_redirect_port=65010
_redirect_uri=http://127.0.0.1:${_redirect_port}

authorize()
{
	check_deps nc ||
		exit 1

	_auth_scope='edit history privatemessages read report save submit'
	_auth_scope="$_auth_scope subscribe vote"
	_auth_scope=$(printf '%s\n' "$_auth_scope" | sed 's/ /%20/g')

	_auth_state=$(LC_CTYPE=C tr -dc "[:alnum:]" </dev/urandom |
		dd bs=1 count=32 2>/dev/null)

	_auth_url=$www_url/authorize/.compact\?client_id=$client_id
	_auth_url=$_auth_url\&response_type=code\&state=$_auth_state
	_auth_url=$_auth_url\&redirect_uri=$_redirect_uri
	_auth_url=$_auth_url\&scope=$_auth_scope\&duration=permanent

	_ext_command=false

	# Check if command for opening the auth url exists
	[ $# -gt 0 ] && {
		debug "Testing if command '$1' exists"

		if command -v "$1" >/dev/null 2>&1; then
			_ext_command=true
		else
			error 1 "command '$1' not found"
		fi
	}

	if $_ext_command; then
		info 'opening authorization link'
		debug "Using external command '$* $_auth_url'"
		"$@" "$_auth_url" &
		_ext_command_pid=$!
	else
		printf 'Visit: \033[4m%s\033[0m\n' "$_auth_url" >&2
	fi

	info 'waiting for redirection from Reddit'

	case $(nc -h 2>&1) in
		*BusyBox*|GNU*|Ncat*)
			set -- -lp "$_redirect_port"
		;;
		# Some netcats need -q (if they have it)
		*'-q '*)
			set -- -lq 1 "$_redirect_port"
		;;

		*)
			set -- -l "$_redirect_port"
		;;
	esac

	# Basic http server, waiting for redirect from reddit auth site
	# Word splitting is intended here
	# shellcheck disable=2046
	set -- $(printf 'HTTP/1.0 200 OK\n\n%s\n' \
		'Done, you can leave this page now' | nc "$@")

	$_ext_command &&
		wait $_ext_command_pid

	# any errors?
	case ${2##*error=} in
		access_denied*)
			info 'permissions denied'
			return 1
		;;
		unsupported_response_type*)
			warn 'invalid response_type parameter' \
				'in initial Authorization'
			return 1
		;;
		invalid_scope*)
			warn 'invalid scope parameter in' \
				'initial Authorization'
			return 1
		;;
		invalid_request*)
			warn 'there was an issue with the' \
				'initial Authorization request'
			return 1
		;;
	esac
	
	_state=${2##*state=}
	_state=${_state%%&code=*}

	[ "$_state" != "$_auth_state" ] && {
		warn 'state mismatch in authorization request'
		return 1
	}

	_code=${2##*&code=}

	debug 'Requesting access token using code' \
		"'$_code' and state '$_state'"

	if get_tokens "$_state" "$_code"; then
		return 0
	else
		return 1
	fi
}

get_tokens()
{
	_state=$1
	_code=$2

	_data=grant_type=authorization_code\&code=$_code
	_data=$_data\&redirect_uri=$_redirect_uri

	_response=$($curl -d "$_data" "$www_url/access_token") || {
		error 1 'something went wrong while' \
			'requesting the access tokens'
		return 1
	}

	IFS=$nl
	# Word splitting is intended here
	# shellcheck disable=2046
	set -- $(printf '%s\n' "$_response" | jq -r '
		.error,
		.access_token,
		.token_type,
		.expires_in,
		.refresh_token,
		.scope')
	IFS=$oifs

	[ "$1" = "null" ] && {
		access_token=$2
		token_expires=$(($(date +%s) + $4))
		refresh_token=$5

		return 0
	}

	case $1 in
		unsupported_grant_type)
			warn 'grant_type parameter was invalid or Http' \
				'Content type was not set correctly' \
				'while trying to get an access token'
		;;

		invalid_grant)
			warn 'the code has expired or already been' \
				'used for getting an access token'
		;;

		*)
			warn "$1"
		;;
	esac

	return 1
}
