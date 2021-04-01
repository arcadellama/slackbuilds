options='f h'
help_text=$(print_help logout '[-fh]' 'log out of account' 0 -f '' \
	'Force logout')

cmd_logout()
{
	parse_options "$@"
	
	# Shift until only trailing arguments remain
	shift $((OPTIND-1))
	OPTIND=1

	[ $# -ne 0 ] &&
		usage "unrecognized argument '$1'"

	$option_h &&
		usage

	! logged_in && ! $option_f && {
		warn 'not logged in'
		return 0
	}

	if $option_f; then
		debug 'Forcing logout'
	else
		debug 'Loggin out'
	fi

	[ -n "${refresh_token:-}" ] && {
		debug 'Revoking access token using' \
			"refresh token '$refresh_token'"
		revoke_token "$refresh_token" || :
	}

	delete_token

	logged_in=false
	info 'logout successful'
}

revoke_token()
{
	if _response=$($curl \
		-d "token=${1}&token_type_hint=refresh_token" \
		"${www_url}/revoke_token")
	then
		debug 'Revoked access token'
		return 0
	else
		warn 'failed to revoke access token'
		return 1
	fi
}
