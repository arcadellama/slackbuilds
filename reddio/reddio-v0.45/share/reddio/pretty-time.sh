pretty_time()
{
	_seconds=${1:-0}

	# Everything under a minute does not need fractions
	if [ "$_seconds" -lt 60 ]; then
		if [ "$_seconds" -lt 1 ]; then
			printf 'just now\n'
		elif [ "$_seconds" -eq 1 ]; then
			printf '1 second ago\n'
		else
			printf '%d seconds ago\n' "$_seconds"
		fi
		return
	fi

	set -- \
	315532800 decade \
	 31536000 year \
	  2626560 month \
	   604800 week \
	    86400 day \
	     3600 hour \
	       60 minute \
		1 second

	until [ "$_seconds" -ge "$1" ]; do
		shift 2
	done

	_n=$((_seconds*100 / $1))
	_int=${_n%??}
	_frac=${_n#$_int}

	# Below 1.05 rounds down to 1 and is singular
	if [ "$_n" -lt 105 ]; then
		printf '1 %s ago\n' "$2"
	# Fractions below 5 round down to 0
	elif [ "$_frac" -lt 5 ]; then
		printf '%d %ss ago\n' "$_int" "$2"
	# Fractions greater than 95 will round up to a whole number
	# We do not want to show the .0
	elif [ "$_frac" -gt 95 ]; then
		LC_NUMERIC=C printf '%.0f %ss ago\n' "$_int.$_frac" "$2"
	# Everything else is shown with one decimal
	else
		LC_NUMERIC=C printf '%.1f %ss ago\n' "$_int.$_frac" "$2"
	fi

	unset _seconds _n _int _frac
}
