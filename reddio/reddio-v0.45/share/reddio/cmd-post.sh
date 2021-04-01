options='h i'

cmd_post()
{
	_command=$1
	shift

	_id_property_name=id
	_multi_target=false

	case $_command in
		delete)
			_endpoint=api/del
			_description='delete comments and submissions'
			_action=deleting
		;;
		follow|unfollow)
			_endpoint=api/follow_post
			_id_property_name=fullname
			_description="$_command comments and submissions"
			_action=${_command}ing
		;;
		hide|unhide)
			_endpoint=api/$_command
			_description="$_command comments and submissions"
			_action=${_command%?}ing
			_multi_target=true
		;;
		marknsfw)
			_endpoint=api/marknsfw
			_description='tag submissions as nsfw'
			_action='tagging as nsfw'
		;;
		unmarknsfw)
			_endpoint=api/unmarknsfw
			_description='remove nsfw tag from submissions'
			_action='removing nsfw tag'
		;;
		read|unread)
			_endpoint=api/${_command}_message
			_description="set message inbox items as"
			_description="$_description $_command"
			_action="setting as $_command"
			_multi_target=true
		;;
		save)
			_endpoint=api/save
			_description='save comments and submissions'
			_action=saving
			options="$options g:"
		;;
		unsave)
			_endpoint=api/unsave
			_description='remove saved comments and'
			_description="$_description submissions"
			_action='removing saved item'
		;;
		spoiler)
			_endpoint=api/spoiler
			_description='tag submissions as spoiler'
			_action='tagging as spoiler'
		;;
		unspoiler)
			_endpoint=api/unspoiler
			_description='remove spoiler tag from submissions'
			_action='removing spoiler tag'
		;;
		subscribe)
			_endpoint=api/subscribe
			_description='subscribe to subreddits'
			_action=subscribing
			_multi_target=true
		;;
		unsubscribe)
			_endpoint=api/subscribe
			_description='unsubscribe from subreddits'
			_action=unsubscribing
			_multi_target=true
		;;
		upvote|downvote)
			_endpoint=api/vote
			_description="$_command comments and submissions"
			_action=${_command%?}ing
		;;
		unvote)
			_endpoint=api/vote
			_description='remove vote from comments and'
			_description="$_description submissions"
			_action='removing vote'
		;;
	esac

	# Generate help text
	_text="Interactively ask for confirmation before $_action"
	case $_command in
		save)
			help_text=$(print_help "$_command" \
				'[-hi] [-g <category>] <target_id>...' \
				"$_description" 7 \
				-i '' "$_text" \
				-g '<group>' 'Add to category <group>'
			)
		;;

		subscribe|unsubscribe)
			help_text=$(print_help "$_command" \
				'[-hi] (<target_id>|<target_name>)...' \
				"$_description" 1 \
				-i '' "$_text"
			)
		;;

		*)
			help_text=$(print_help "$_command" \
				'[-hi] <target_id>...' \
				"$_description" 1 \
				-i '' "$_text"
			)
		;;
	esac

	parse_options "$@"

	$option_h && usage

	# Shift until only trailing arguments remain
	shift $((OPTIND-1))
	OPTIND=1

	[ $# -eq 0 ] &&
		usage 'missing target'

	! logged_in && {
		warn 'not logged in'
		exit 1
	}

	# If interactive, prompt the user until we get valid input
	$option_i && while :; do
		printf '%s: %s '%s'? (y/N) ' \
			"$prog_name" "$_command" "$*" >&2
		read -r _reply
		case $_reply in
			[yY]|[yY][eE][sS]) break ;;
			[nN]|[nN][oO]|'') exit 1 ;;
		esac
	done

	# API endpoints accepting a comma-separated list of targets
	$_multi_target && {
		_target=
		for _arg do
			_target=$_target,$_arg
		done
		set -- "${_target#,}"
	}

	_targets=$*
	set --

	# Assemble data parameters
	case $_command in
		downvote) set -- -d dir=-1 -d rank=2 ;;
		upvote)   set -- -d dir=+1 -d rank=2 ;;
		unvote)   set -- -d dir=0 -d rank=2 ;;
		follow)   set -- -d follow=true ;;
		unfollow) set -- -d follow=false ;;

		save)
			$option_g &&
				set -- --data-urlencode \
					"category=$param_g"
		;;

		subscribe|unsubscribe)
			# The first target determines if we use fullnames
			# or names
			case $_targets in
				t5_*) _id_property_name=sr ;;
				*)    _id_property_name=sr_name ;;
			esac

			case $_command in
				sub*) set -- -d action=sub ;;
				*)    set -- -d action=unsub ;;
			esac
		;;
	esac

	for _arg in $_targets; do
		debug "$_command $_arg"

		query "$_endpoint" "$@" --data-urlencode \
			"$_id_property_name=$_arg" >/dev/null \
		|| error 1 "failed $_action '$_arg'"
	done
}
