#!/bin/sh
function echo_info() {
  local what=$*
  echo -e "\e[1;32m ${what} \e[0m"
}

function echo_warning() {
  local what=$*
  echo -e "\e[1;33m ${what} \e[0m"
}

function echo_error() {
  local what=$*
  echo -e "\e[1;31m ${what} \e[0m"
}

if [ "$(id -u)" -ne "0" ]; then
  echo_warning "------ 请使用 root 权限执行安装脚本 ------ \n"
  exit 1
fi

echo_info "------ 开始设置 Nginx 源 ------ \n"
cat >>/etc/apt/sources.list.d/nginx.list <<"EOF"
deb http://nginx.org/packages/mainline/debian/ buster nginx
deb-src http://nginx.org/packages/mainline/debian/ buster nginx
EOF

echo_info "------ 添加 Nginx 公钥 ------ \n"
wget http://nginx.org/keys/nginx_signing.key &&  apt-key add nginx_signing.key

echo_info "------ 开始安装 Nginx ------ \n"
apt update && apt install nginx -y
