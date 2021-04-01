refresh_token()
{
	_data=grant_type=refresh_token\&refresh_token=$refresh_token

	_response=$($curl -d "$_data" "$www_url/access_token") ||
		error 1 'something went wrong while' \
			'refreshing the access token'

	IFS=$nl
	# Word splitting is intended here
	# shellcheck disable=2046
	set -- $(printf '%s\n' "$_response" | jq -r '
		.error,
		.access_token,
		.token_type,
		.expires_in,
		.scope')
	IFS=$oifs

	unset _data _response

	[ "$1" = "null" ] && {
		access_token=$2
		token_expires=$(($(date +%s) + $4))

		debug 'Got new access token'

		write_token \
			"$token_expires" \
			"$access_token" \
			"$refresh_token"

		return 0
	}

	case $1 in
		unsupported_grant_type)
			warn 'grant_type parameter was invalid' \
				'or Http Content type was not' \
				'set correctly'
		;;

		*)
			warn "could not refresh token: $1"
		;;
	esac
	return 1
}
