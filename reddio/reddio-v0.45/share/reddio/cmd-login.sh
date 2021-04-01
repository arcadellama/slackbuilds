options='f h'
help_text="$(print_help login '[-fh] [<command>]' 'log in to account' 0 \
	-f '' 'Force login when already logged in')

In order to grant $prog_name permissions to access Reddit, it is required
to visit Reddits authentication website. The link to that website will be
printed to stderr. If <command> is specified, the link will be opened
using that command."

cmd_login()
{
	parse_options "$@"
	
	# Shift until only trailing arguments remain
	shift $((OPTIND-1))
	OPTIND=1

	$option_h &&
		usage

	logged_in && ! $option_f && {
		warn 'already logged in'
		return 0
	}

	if $option_f; then
		debug 'Forcing login'
	else
		debug 'Logging in'
	fi

	. "$lib_dir"/oauth.sh

	if authorize "$@"; then
		write_token \
			"$token_expires" \
			"$access_token" \
			"$refresh_token"

		info 'login successful'
		logged_in=true
	else
		warn 'authorization failed'
		return 1
	fi
}
