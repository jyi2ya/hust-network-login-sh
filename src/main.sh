#!/bin/sh

LC_ALL=C
LANG=C
export LC_ALL LANG

urlencode()
{
	printf '%s' "$1" | sed 's/./&\n/g' | while read -r char; do
		case "$char" in
			[a-zA-Z0-9.~_-]) printf '%s' "$char" ;;
			*) printf '%%%02X' "'$char" ;;
		esac
	done
}

die()
{
	err="$2"
	[ -z "$err" ] && err=1
	printf "%s\n" "$1"
	exit "$err"
}

check_cmd()
{
	fail=""
	for cmd in nc unix2dos awk grep printf sed sleep; do
		if ! command -v "$cmd" >/dev/null; then
			echo "Cannot find command: $cmd"
			fail=y
		fi
	done
	[ -z "$fail" ] || die "Util(s) missing"
}

nc_skip_header()
{
	awk '
		header_finished { print }
		/^\r$/ { header_finished = 1 }
	'
}

nc_get()
{
	domain="$1"
	timeout="$2"
	unix2dos <<EOF | nc "$domain" -w "$timeout" | nc_skip_header
GET / HTTP/1.1
Host: $domain
User-Agent: curl/7.74.0
Accept: */*

EOF
}

nc_post()
{
	domain="$1"
	path="$2"
	timeout="$3"
	body="$4"

	{
		unix2dos <<EOF
POST $path HTTP/1.1
Host: $domain
Accept: */*
User-Agent: hust-network-login
Content-Length: 534
Content-Type: application/x-www-form-urlencoded; charset=UTF-8

EOF
		printf '%s' "$body"
	} | nc "$domain" -w "$timeout" | nc_skip_header
}

login()
{
	username="$1"
	password="$2"

	resp=$(nc_get "www.baidu.com:80" 10)

	[ -z "$resp" ] && die "baidu boom!"

	if ! printf '%s' "$resp" | grep -q '/eportal/index.jsp'; then
		return 0
	fi

	portal_ip=$(printf '%s' "$resp" | sed 's#^[^/]*//\([^/]*\).*$#\1#')
	echo "portal ip: $portal_ip"

	query_string=$(printf '%s' "$resp" | sed "s#.*index.jsp?\([^']*\).*#\1#")
       	echo "query_string: $query_string"

	query_string=$(urlencode "$query_string")

	body="userId=$username&password=$password&service=&queryString=$query_string&passwordEncrypt=false"

	resp=$(nc_post "$portal_ip" "/eportal/InterFace.do?method=login" 10 "$body")

	echo "login resp: $resp"

	if printf '%s' "$resp" | grep -q 'success'; then
		return 0
	else
		return 1
	fi
}

main()
{
	read -r username
	read -r password

	while :; do
		if login "$username" "$password"; then
			echo "login ok. awaiting..."
			sleep 15
		else
			echo "error!"
			sleep 1
		fi
	done
}

check_cmd
[ -n "$1" ] || die "give me your config filename, you idiot"
main < "$1"
