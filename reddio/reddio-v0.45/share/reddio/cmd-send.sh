options='h i t:'
editor=${REDDIO_EDITOR:-${editor:-${VISUAL:-${EDITOR:-vi}}}}

cmd_send()
{
	_command=$1
	shift

	_i_text='Interactively ask for confirmation before'

	# Prepare help text and options
	case $_command in
	comment)
		x='The text to send. Without this option, an external'
		x="$x editor"

		help_text=$(print_help \
			"$_command" '[-hi] [-t <text>] <target_id>' \
			'submit comments' 6 \
			-i '' "$_i_text submitting" \
			-t '<text>' "$x" \
			'  ' '' 'is opened'
		)
		help_text="$help_text$nl${nl}Example: $prog_name"
		help_text="$help_text $_command -t \"Hello, world!\""
		help_text="$help_text t3_anid36"
	;;
	edit)
		x='The new text to use. Without this option, an external'

		help_text=$(print_help \
			"$_command" '[-hi] [-t <text>] <target_id>' \
			'edit comments and selfposts' 6 \
			-i '' "$_i_text editing" \
			-t '<text>' "$x" \
			'  ' '' 'editor is opened'
		)
		help_text="$help_text$nl${nl}Example: $prog_name"
		help_text="$help_text $_command -t \"New text\" t3_anid36"
	;;
	message)
		x='The text to send. Without this option, an external'
		x="$x editor"

		_synopsis="[-hi] [-t <text>]$nl             "
		_synopsis="$_synopsis (<message_id>|<username>"
		_synopsis="$_synopsis <subject>)"

		help_text=$(print_help \
			"$_command" "$_synopsis" 'send messages' 6 \
			-i '' "$_i_text sending" \
			-t '<text>' "$x" \
			'  ' '' 'is opened'
		)
		help_text="$help_text$nl${nl}Example: $prog_name"
		help_text="$help_text $_command -t \"Hello, randomuser\""
		help_text="$help_text randomuser \"A subject\"$nl        "
		help_text="$help_text $prog_name $_command -t \"This is a"
		help_text="$help_text reply\" t4_msgid36"
	;;
	submit)
		options="$options f m s w l:"

		_synopsis="[-fhimns] [-l <url>|-t <text>]$nl"
		_synopsis="$_synopsis              <subreddit> <title>"
		_m_text='Mute. Do not send replies to the message inbox'
		_t_text='The selfpost text to submit. Without this'
		_t_text="$_t_text option, an"

		help_text=$(print_help \
			"$_command" "$_synopsis" \
			'submit links and selfposts' 6 \
			-i '' "$_i_text submitting" \
			-f '' 'Force re-submission' \
			-m '' "$_m_text" \
			-w '' 'Mark as not suited for work (nsfw)' \
			-s '' 'Mark as spoiler' \
			-l '<url>' 'The link url to submit' \
			-t '<text>' "$_t_text" \
			'  ' '' 'external editor is opened'
		)
		help_text="$help_text$nl${nl}Example: $prog_name"
		help_text="$help_text $_command -l http://localhost"
		help_text="$help_text funny \"Submission title\""
	;;
	esac

	debug 'Parsing send sub-command arguments'

	parse_options "$@"
	shift $((OPTIND-1))
	OPTIND=1

	$option_h && usage

	[ $# -eq 0 ] &&
		usage 'missing target'

	_target=$1
	shift

	# Set curl options and url
	case $_command in comment|edit)
		[ $# -gt 0 ] &&
			usage "trailing arguments not allowed '$*'"
		set -- --data-urlencode "thing_id=$_target"
	esac

	case $_command in
		comment)
			_url=api/comment
			case $_target in
				t[14]_*) _prompt='Reply to' ;;
				*) _prompt='Comment on' ;;
			esac
			debug "Submitting comment to '$_target'"
		;;
		edit)
			_url=api/editusertext
			_prompt=Edit
			debug "Editing '$_target'"
		;;
		message)
			case $_target in
				t4_*)
					[ $# -gt 0 ] && {
						warn "ignoring trailing" \
							"subject" "'$*'"
					}
					_url=api/comment
					_prompt='Reply to'
					set -- --data-urlencode \
						"thing_id=$_target"
				;;
				*)
					[ $# -eq 0 ] &&
						usage 'missing subject'

					_url=api/compose
					_prompt='Send message to'
					set -- --data-urlencode \
						"to=$_target" \
						--data-urlencode \
						"subject=$*"
				;;
			esac

			debug "Sending message to '$_target'"
		;;
		submit)
			[ $# -eq 0 ] &&
				usage 'missing title'

			_url=api/submit

			$option_l && $option_t && {
				option_t=false
				param_t=
				warn 'ignoring text because of -l'
			}

			if $option_l; then
				_prompt='Submit link to'
				# This is not supposed to be a command
				# shellcheck disable=2209
				_kind=link
			else
				_prompt='Submit selfpost to'
				_kind=self
			fi

			set -- -d extension=json \
				-d "kind=$_kind" \
				-d "resubmit=$option_f" \
				-d "nsfw=$option_w" \
				-d "spoiler=$option_s" \
				-d "sendreplies=$option_m" \
				--data-urlencode "title=$*" \
				--data-urlencode "sr=${_target#r/}"

			$option_l &&
				set -- "$@" \
					--data-urlencode "url=$param_l"

			debug "Submitting to '$_target'"
		;;
	esac

	! logged_in && {
		warn 'not logged in'
		exit 1
	}

	# Open the users editor to write the text
	! ${option_l:-false} && ! $option_t && {
		if [ -t 0 ]; then
			_tmp_file=${TMPDIR:-/tmp}/reddio-$$.md
			[ -e "$_tmp_file" ] &&
				error 1 "temporary file '$_tmp_file'" \
					"already exists"

			: >"$_tmp_file"
			chmod 600 "$_tmp_file"

			debug "Opening editor '$editor'"
			$editor "$_tmp_file"

			param_t=$(cat -- "$_tmp_file")
		else
			param_t=$(cat -)
		fi
	}

	! ${option_l:-false} && [ -z "$param_t" ] && {
		[ -n "${_tmp_file:-}" ] && [ -f "$_tmp_file" ] &&
			rm -- "$_tmp_file"

		error 1 'missing text'
	}

	set -- "$@" -d api_type=json --data-urlencode "text=${param_t:-}"

	$option_i && {
		# Prompt until we get a valid answer
		while :; do
			printf "%s: %s '%s'? (y/N) " \
				"$prog_name" "$_prompt" "$_target" >&2

			read -r _reply

			case $_reply in
				[yY]|[yY][eE][sS])
					break
				;;
				[nN]|[nN][oO]|'')
					[ -n "${_tmp_file:-}" ] &&
					warn "keeping message file" \
						"'$_tmp_file'"
					exit 0
				;;
			esac
		done
	}

	_errors=$(query "$_url" "$@" \
		| jq -r '[.json.errors[] | .[1]] | join(" and ")')

	[ -n "$_errors" ] && {
		[ -n "${_tmp_file:-}" ] && [ -f "$_tmp_file" ] && {
			_errors="${_errors}. Keeping message file"
			_errors=" '$_tmp_file'"
		}

		error 1 "$_errors"
	}

	# Delete temporary file if it exists
	[ -n "${_tmp_file:-}" ] && [ -f "$_tmp_file" ] &&
		rm -- "$_tmp_file"

	return 0
}
