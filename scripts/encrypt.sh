#!/bin/sh

LC_ALL=C
LANG=C
export LC_ALL LANG

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

result=$(enc "$@")
echo "$result"
