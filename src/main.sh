#!/bin/sh

LC_ALL=C
LANG=C
export LC_ALL LANG

info() {
    echo "[$(date)]" "$@" >&2
}

enc() {
    enc_text="$1"
    enc_c=$(printf '%s' "$enc_text" | od -An -t x1 -w1 -v | tr -d '\n ' | tr '[:lower:]' '[:upper:]')
    enc_e=10001
    enc_n=94DD2A8675FB779E6B9F7103698634CD400F27A154AFA67AF6166A43FC26417222A79506D34CACC7641946ABDA1785B7ACF9910AD6A0978C91EC84D40B71D2891379AF19FFB333E7517E390BD26AC312FE940C340466B4A5D4AF1D65C3B5944078F96A1A51A5A53E4BC302818B7C9F63C4A1B07BD7D874CEF1C3D4B2F5EB7871
    enc_result=$(
    cat <<EOF | BC_LINE_LENGTH=0 bc -q
scale = 0
obase = 16
ibase = 16
x = $enc_c
y = $enc_e
m = $enc_n
ans = 1

while (y) {
    if (y % 2 == 1) {
        ans = ans * x % m
    }
    x = x * x % m
    y /= 2
}

ans
EOF
)
    printf '%256s' "$enc_result" | tr '[:upper:]' '[:lower:]' | tr ' ' '0'
}

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
	port="$2"
	unix2dos <<EOF | nc "$domain" "$port" | nc_skip_header
GET / HTTP/1.1
Host: $domain
User-Agent: curl/7.74.0
Accept: */*

EOF
}

nc_post()
{
	domain="$1"
	port="$2"
	path="$3"
	body="$5"

	{
		unix2dos <<EOF
POST $path HTTP/1.1
Host: $domain
Accept: */*
User-Agent: hust-network-login
Content-Length: ${#body}
Content-Type: application/x-www-form-urlencoded; charset=UTF-8

EOF
		printf '%s' "$body"
	} | nc "$domain" "$port" | nc_skip_header
}

login()
{
	username="$1"
	password="$2"

	resp=$(nc_get "www.baidu.com" 80)

    if [ -z "$resp" ]; then
        info "baidu boom!"
        return 1
    fi

	if ! printf '%s' "$resp" | grep -q '/eportal/index.jsp'; then
		return 0
	fi

	portal_ip=$(printf '%s' "$resp" | sed 's#^[^/]*//\([^/]*\).*$#\1#')
	info "portal ip: $portal_ip"

    mac=$(printf '%s' "$resp" | sed 's#.*mac=\([^&][^&]*\).*#\1#')
	info "mac: $mac"

    info "encrypting password, may take a long time"
    encrypt_pass=$(enc "$password>$mac")
    info "encrypt done"

    query_string=$(printf '%s' "$resp" | sed "s#.*index.jsp?\([^']*\).*#\1#")
    info "query_string: $query_string"

	query_string=$(urlencode "$query_string")

	body="userId=$username&password=$encrypt_pass&service=&queryString=$query_string&passwordEncrypt=true"

	post_ip=$(printf '%s' "$portal_ip" | sed 's/:.*//')
	post_port=$(printf '%s' "$portal_ip" | sed 's/.*://')

	resp=$(nc_post "$post_ip" "$post_port" "/eportal/InterFace.do?method=login" "$body")

	info "login resp: $resp"

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
			info "login ok. awaiting..."
			sleep 15
		else
			info "error!"
			sleep 1
		fi
	done
}

check_cmd
[ -n "$1" ] || die "give me your config filename, you idiot"
main < "$1"
