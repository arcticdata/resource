#!/bin/bash
# 执行命令 bash install_online.sh --path=路径 --user=用户名  --passwd=密码
###############  --path  可设置参数 ############################################
function main() {
	ARGS=$(getArgs "$@")
	path=$(echo "$ARGS" | getNamedArg path)
	user=$(echo "$ARGS" | getNamedArg user)
	passwd=$(echo "$ARGS" | getNamedArg passwd)
}
function getArgs() {
	for arg in "$@"; do
		echo "$arg"
	done
}
function getNamedArg() {
	ARG_NAME=$1

	sed --regexp-extended --quiet --expression="
        s/^--$ARG_NAME=(.*)\$/\1/p  # Get arguments in format '--arg=value': [s]ubstitute '--arg=value' by 'value', and [p]rint
        /^--$ARG_NAME\$/ {          # Get arguments in format '--arg value' ou '--arg'
            n                       # - [n]ext, because in this format, if value exists, it will be the next argument
            /^--/! p                # - If next doesn't starts with '--', it is the value of the actual argument
            /^--/ {                 # - If next do starts with '--', it is the next argument and the actual argument is a boolean one
                # Then just repla[c]ed by TRUE
                c TRUE
            }
        }
    "
}
main "$@"

###############  设置 echo 输出字体颜色   ############################################
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
###############  开始安装服务   ############################################
echo_info "------ 开始安装北极数据服务 ------ \n"

if [ "$(id -u)" -ne "0" ]; then
	echo "请使用 root 权限执行安装脚本"
	exit 1
fi

docker --version >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
	echo_info "------ docker 已经存在、继续执行 ------ \n"
else
	echo_warning "------ docker 不存在 ------ \n"
	echo_info "------ 准备安装 docker 中 ------ \n"
	wget -O get-docker.sh https://gitee.com/ldsink/toolbox/raw/master/get-docker.sh && chmod +x get-docker.sh && ./get-docker.sh --mirror Aliyun && systemctl start docker && systemctl enable docker
fi

docker-compose --version >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
	echo_info "------ docker-compose 已存在 ------ \n"
else
	echo_warning "------ docker-compose 不存在 ------ \n"
	echo_info "------ 准备安装 docker-compose ------ \n"
        version=1.29.2
# 官方原链接 curl -L https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
	wget -O docker-compose https://r.datarc.cn/deploy/20211215/docker-compose && mv docker-compose /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
	ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

echo_info "------ 正在登录私有仓库中 ------   \n"
docker login --username=$user --password=$passwd dockerhub.qingcloud.com

echo_info "------ 创建项目目录中 ------   \n"
mkdir -p $path

echo_info "------ 创建授权证书中 ------   \n"

if [ ! -f "licence.key" ]; then
	echo_info "------ 未找到北极数据授权证书、请将授权证书移动至当前目录 ... 三秒后退出 ------   \n"
	sleep 3
	exit 1
fi

cp licence.key $path/

echo_info "------ 创建服务配置文件 ------   \n"

if [ ! -f "configs.py" ]; then
	echo_info "------ 未找到北极数据服务配置文件、请将服务配置文件移动至当前目录 ... 三秒后退出 ------   \n"
	sleep 3
	exit 1
fi

cp configs.py $path/ && cd $path/

echo_info "------ 正在拉取环境变量文件 ------   \n"
wget -O .env https://r.datarc.cn/deploy/20211215/.env

echo_info "------ 正在拉取编排文件 ------   \n"
wget -O docker-compose.yml https://r.datarc.cn/deploy/20211215/docker-compose.yml

echo_info "------ 正在拉取更新脚本 ------   \n"
wget -O update.sh https://r.datarc.cn/deploy/20211215/update.sh && chmod +x update.sh

echo_info "------ 正在启动服务、请稍等 ------   \n"
./update.sh

echo_info "------ 初始化服务后台账号、请稍等 ------   \n"
a=$(echo ${PWD##*/})
docker exec -i "${a}"_web_1 pipenv run python manage.py initialize
