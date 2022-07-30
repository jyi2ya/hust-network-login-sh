#!/bin/bash

if [[ "$(whoami)" != "root" ]]; then
  echo 'please run this script under root or with command sudo'
  exit 1
fi

(
  cd "$(dirname "$0")" || exit 1

  conf='/etc/hust-network-login-sh/conf'
  echo 'mkdir /etc/hust-network-login-sh/ -p'
  mkdir /etc/hust-network-login-sh/ -p
  echo "cp conf $conf"
  cp ./conf "$conf"
#  echo "chmod o= $conf"
#  chmod o= "$conf"

  target='/usr/bin/hust-network-login-sh'
  if [[ ! -x /usr/bin/hust-network-login-sh ]]; then
    echo "cp ../src/main.sh $target"
    cp ../src/main.sh "$target"
    chmod +x "$target"
  fi

  echo 'cp ./hust-network-login-sh.service /etc/systemd/system/'
  cp ./hust-network-login-sh.service /etc/systemd/system/

  systemctl daemon-reload
  echo 'start hust-network-login-sh.service'
  systemctl enable hust-network-login-sh --now
)

