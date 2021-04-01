options='A a: b: c: f: h i: l: m s: t:'
help_text="$(print_help print '[<options>] [<listing>]' 'print listings' \
	9 \
	-A '' \
	'Show all. Filters such as "hide links that I have voted' \
	'  ' '' 'on" will be disabled' \
	-a '<id>' \
	"Show items after <id>. This is Reddits' pagination. See" \
	'  ' '' 'https://www.reddit.com/dev/api for more information' \
	-b '<id>' 'Show items before <id>. See -a' \
	-c '<when>' 'When to use colors, never, always or auto' \
	-f '<format>' 'Format string used for the output' \
	-i '<width>' \
	'Indent comments and messages by <width> spaces times the' \
	'  ' '' 'nesting depth' \
	-l '<num>' 'Limit to <num> items' \
	-m '' \
	'Mark all messages read when requesting message/* listings' \
	-s '<order>' \
	'Sort order of the listing. When requesting submissions' \
	'  ' '' 'of a subreddit, <order> is one of: hot new rising' \
	'  ' '' 'controversial top gilded. For comments one of:' \
	'  ' '' 'confidence top new controversial old random qa live' \
	-t '<time>' \
	'Timeframe for the top and controversial listings, <time>' \
	'  ' '' 'is one of: hour day week month year all')

Common listings:
  comments/<id>
  r/<subreddit>/{hot,new,rising,controversial,top,gilded}
  r/<subreddit>/{about,comments}
  user/<yourname>/m/<multiname>/{hot,new,rising,controversial,top,gilded}
  user/<username>
  user/<username>/{about,comments,submitted,gilded}
  user/<username>/{upvoted,downvoted,hidden,saved}
  message/{inbox,unread,messages,comments,selfreply,mentions,sent}
  info/<id1>,<id2>,<id3>...
  by_id/<submission1_id>,<submission2_id>,<submission3_id>..."

##########################################################################

# The $format variable will be evaluated, so the variables within single
# quotes are intended
# shellcheck disable=2016
set_formats() {
	# Environment has precedence over config variable
	[ -n "${REDDIO_FORMAT:-${format:-}}" ] && {
		format=${REDDIO_FORMAT:-$format}
		return
	}

	# Trying to stay below 75 columns makes this pretty ugly

	# t1 Comments
	f='${is_comment:+'
	f=$f'$fg7${up:+$bld$fg2}${down:+$bld$fg1}${show_score:+$score}'
	f=$f'${hide_score:+-}$rst$fg7 ${stickied:+[S] }'
	f=$f'${is_submitter:+$fg4}$author'
	f=$f'${distinguished:+[$distinguished]}${is_submitter:+$fg7}'
	f=$f' $created_pretty${edited:+*} $fg3$id$rst'
	f=$f'${is_mixed:+ ($link_id)'
	f=$f'$nl$fg7$link_title$rst (r/$subreddit)}'
	f=$f'$nl$text$nl$nl}'

	# t2 User
	f=$f'${is_user:+'
	f=$f'$name${is_friend:+[F]} joined $created_pretty$fg3$id$rst'
	f=$f'$nl$comment_karma comment karma'
	f=$f'$nl$link_karma submission karma$nl}'

	# t3 Submission (link)
	f=$f'${is_link:+'
	f=$f'$fg7${up:+$bld$fg2}${down:+$bld$fg1}${show_score:+$score}'
	f=$f'${hide_score:+-}$rst$fg7 $title$rst ($domain)'
	f=$f'$nl$ul$url$rst'
	f=$f'$nl${tags:+$tags }$num_comments comment$comments_plural'
	f=$f' | submitted $created_pretty${edited:+*} by'
	f=$f' ${is_comments:+$fg4}$author'
	f=$f'${distinguished:+[$distinguished]}$rst on r/$subreddit $fg3'
	f=$f'$id$rst'
	f=$f'$nl${is_comments:+${text:+'
	f=$f'$fg7------------------------------$rst'
	f=$f'$nl$text$nl}}$nl}'

	# t4 Messages
	f=$f'${is_msg:+'
	f=$f'${fg7}${author:=r/$subreddit}'
	f=$f'${distinguished:+[$distinguished]} to $dest $created_pretty'
	f=$f' $fg3$id${parent_id:+$rst ($parent_id)}'
	f=$f'$nl$fg7$subject$rst'
	f=$f'$nl$text$nl$nl}'

	# t5 Subreddit
	f=$f'${is_sub:+'
	f=$f'r/$name $fg3$id$rst'
	f=$f'$nl$title'
	f=$f'$nl${nl}A $type subreddit with $subscribers subscriber(s)'
	f=$f' created $created_pretty${description:+'
	f=$f'$nl------------------------------'
	f=$f'$nl$description}${submit_text:+'
	f=$f'$nl------------------------------'
	f=$f'$nl$submit_text}${text:+'
	f=$f'$nl------------------------------'
	f=$f'$nl$text}$nl}'

	# More / Continue
	f=$f'${is_more:+'
	f=$f'$fg7$count more$rst'
	f=$f'$nl$nl}${is_continue:+'
	f=$f'${fg7}Thread continues$rst$nl$nl}'

	format=$f
	unset f
}

_once_done=false

only_once()
{
	$_once_done && return
	_once_done=true

	parse_options() { :; }

	logged_in && check_token
	. "$lib_dir"/pretty-time.sh

	# Defaults
	: "${param_c:=auto}"
	: "${param_i:=2}"
	: "${param_l:=99999}"

	$option_c && case $param_c in
		auto|always|never) : ;;
		*) usage "invalid color parameter '$param_c'" ;;
	esac

	$option_i && case $param_i in
		*[!0-9]*) usage "invalid indent parameter '$param_i'" ;;
	esac

	$option_l && case $param_l in
		*[!0-9]*) usage "invalid limit parameter '$param_l'" ;;
	esac

	$option_s && case $param_s in
		hot|new|rising|controversial|top|gilded) : ;;
		*) usage "invalid sort parameter '$param_s'" ;;
	esac

	$option_t && case $param_t in
		hour|day|week|month|year|all) : ;;
		*) usage "invalid time parameter '$param_t'" ;;
	esac

	# Print help after all option parsing is done
	$option_h && usage

	if
		[ "$param_c" = auto ] && [ -t 1 ] ||
		[ "$param_c" = always ]
	then
		. "$lib_dir"/color-formats.sh
	fi

	if $option_f; then
		format=$param_f
	else
		set_formats
	fi

	_now=$(date +%s)
}

cmd_print()
{
	debug "Parsing print sub-command arguments"
	parse_options "$@"
	shift $((OPTIND-1))
	OPTIND=1
	_listing=${1:-}
	debug "$_listing"

	# Only one trailing argument allowed
	[ "$#" -gt 1 ] &&
		usage 'too many arguments'

	only_once

	# Parse trailing argument
	_listing_type=sub
	[ -n "${_listing:-}" ] && {
		# Remove trailing ?... and &... to prevent attributes
		# in the listing argument
		_listing=${_listing%%[?&]*}

		# Remove leading and trailing slashes
		_listing=${_listing#/}
		_listing=${_listing%/}

		case $_listing in
			morechildren/?*)
				# This is not supposed to be a command
				# shellcheck disable=2209
				_listing_type=more
				link_id=${_listing#*/}
				link_id=${link_id%%/*}
				_children=${_listing##*/}
				_listing=api/morechildren
			;;

			r/?*/about)       _listing_type=about_sub ;;
			user/?*/about)    _listing_type=about_user ;;
			user/?*)          _listing_type=user ;;
			comments/?*)      _listing_type=comments ;;
			r/?*/comments/?*) _listing_type=comments ;;
			r/?*/comments)    _listing_type=sub_comments ;;
			r/?*)             _listing_type=sub ;;
			message/?*)       _listing_type=messages ;;
			by_id/?*)         _listing_type=by_id ;;

			info/?*)
				_listing_type=info
				_ids=${_listing#*/}
				_listing=api/info
			;;

			*)
				# TODO: error out on unknown listing type?
				warn "unknown listing type '$_listing'"
				_listing_type=unknown
			;;
		esac

		debug "Listing is of type '$_listing_type'"
	}

	# Remove t3_ prefix
	[ "$_listing_type" = comments ] && {
		case $_listing in *comments/t3_?*)
			_listing=comments/${_listing#*t3_} ;;
		esac
	}

	# Assemble the URL
	_url=${_listing:+$_listing/}
	_url=$_url\?raw_json=1\&threaded=0
	_url=$_url${param_A:+&show=all}
	_url=$_url${param_a:+&after=$param_a}
	_url=$_url${param_b:+&before=$param_b}
	_url=$_url${_ids:+&id=$_ids}
	_url=$_url\&limit=$param_l
	_url=$_url${param_s:+&sort=$param_s}
	_url=$_url${param_t:+&t=$param_t}

	case $_listing_type in
		more)
			_url=$_url\&api_type=json
			_url=$_url\&limit_children=false
			_url=$_url\&link_id=$link_id
			_url=$_url\&children=$_children
		;;
	esac

	: "${num:=0}"

	set -- "$param_i" $_listing_type "$format" "$option_l" "$@"

	# TODO: jq error handling
	# reddit api doesn't send json when requesting invalid listings
	query "$_url" \
	| sed -E -e 's%([^\](\\\\)*\\)n%\1r%g' -e 'tx' -e 'b' \
		-e ':x' -e 's%([^\](\\\\)*\\)n%\1r%g' \
	| jq -j --unbuffered -f "$lib_dir"/listings.jq 2>/dev/null \
	| print_formatted "$@"

	_retval=$?

	[ "$_listing_type" = messages ] && $option_m && {
		query api/read_all_messages?raw_json=1 \
			--data-urlencode "filter_types="
	}

	return $_retval
}

# In this function, we set a lot of variables whichs names are to be used
# in $format. Disable shellcheck warnings about unused variables
# shellcheck disable=2034
print_formatted() {
	_indent=$1
	_type=$2
	_format=$3
	_limit=$4
	shift 4

	# is_mixed is used to conditionally print the link title and
	# subreddit of a comment
	case $_type in info|sub_comments|user|messages)
		is_mixed=1 ;;
	esac

	while read -r line; do
		# Unset variables which might be set from
		# previous iterations
		unset -v is_comments is_comment is_user \
			is_link is_msg is_sub is_more is_continue

		case $line in
			*$cr*)
				eval "$(printf %s "$line" | tr \\r \\n)"
			;;
			*)
				eval "$line"
			;;
		esac

		case $kind in
			t1) is_comment=1
				# Reddit API is so retardedly inconsistent
				# because comments in "message/..."
				# listings miss link_id As a work-around,
				# we can extract the link_id from
				# "context"
				[ -z "$link_id" ] && {
					link_id=${context#*/comments/}
					link_id=t3_${link_id%%/*}
				}
			;;
			t2)
				is_user=1
			;;
			t3)
				is_link=1
				# is_comments is used to conditionally
				# print the text of a self-post
				[ "$_type" = comments ] \
				&& is_comments=1
			;;
			t4)
				is_msg=1
				# TODO: json is threaded but has no depth
				# variable
			;;
			t5)
				is_sub=1
			;;
			more)
				if [ "$count" != 0 ]; then
					is_more=1
	
					# recursively load all comments
					! $_limit && {
						x=morechildren/$link_id
						x=$x/$children
						print "$x"
						continue
					}
				else
					is_continue=1
				fi
			;;
		esac

		num=$((num+1))

		case ${distinguished:=} in
			moderator)
				admin=; moderator=1; special=
				distinguished=M
			;;
			admin)
				admin=1; moderator=; special=
				distinguished=A
			;;
			special)
				admin=; moderator=; special=1
				distinguished=S
			;;
			*)
				admin=; moderator=; special=
				distinguished=
			;;
		esac

		tags=${over18:+[NFSW]}${spoiler:+[Spoiler]}
		tags=$tags${saved:+[Saved]}${archived:+[A]}
		tags=$tags${gilded:+[G]}${locked:+[L]}
		tags=$tags${pinned:+[P]}${stickied:+[S]}

		# Format variables containing an 's' or nothing depending
		# on the respective variable being singular or plural
		case ${num_comments:-1} in
			1) comments_plural= ;;
			*) comments_plural=s ;;
		esac

		case ${score:-1} in
			-1|1) score_plural= ;;
			*) score_plural=s ;;
		esac

		created_pretty=$(pretty_time $((_now-created)))
		[ -n "${edited:-}" ] &&
			edited_pretty=$(pretty_time $((_now-edited)))

		set +eu
		# Print with indentation
		if
			[ -n "$depth" ] &&
			[ "$_indent" -gt 0 ] &&
			[ "$depth" -gt 0 ]
		then
			_pre=$(printf %$((_indent*depth))s)

			eval "printf %s \"$_format\" \
				| sed \"s/^/$_pre/\""
		else
			eval "printf %s \"$_format\""
		fi
		set -eu
	done

	# Return non-zero if no items where printed
	[ $num -gt 0 ]
}
