#!/bin/bash
# 执行命令 bash install_online.sh --path=<路径> --username=<用户名> --password=<密码> --image_version=<X.X.X>  
# 说明 --username --password 为必填值
###############  --path  可设置参数 ############################################
datarc_verion=20220723
datarc_dir=
function main() {
  ARGS=$(getArgs "$@")
  path=$(echo "$ARGS" | getNamedArg path) ; [ ! $path ] && path='/opt/datarc'
  username=$(echo "$ARGS" | getNamedArg username)
  password=$(echo "$ARGS" | getNamedArg password)
  image_version=$(echo "$ARGS" | getNamedArg image_version) ; [ ! $image_version ] && image_version='2.8.0'
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
HOSTNAME_IP=$(hostname -I | awk '{print $1}')
function install() {
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
    wget -O docker-compose https://r.datarc.cn/deploy/docker-compose && mv docker-compose /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  fi

  echo_info "------ 正在登录私有仓库中 ------   \n"
  docker login --username=$username --password=$password dockerhub.qingcloud.com

  echo_info "------ 创建项目目录中 ------   \n"
  mkdir -p $path

  echo_info "------ 创建服务配置文件 ------   \n"
  if [ ! -f "${path}/configs.py" ]; then
    if [ -f "configs.py" ]; then
      cp "configs.py" "${path}" && cd ${path}/
    else
      touch ${path}/configs.py
    fi
  fi
  cd ${path}/
  echo_info "------ 正在拉取环境变量文件 ------   \n"
  cat >${path}/.env <<EOF
# 将文中 127.0.0.1 替换为 实际 <IP> , <域名> , 端口如果被占用 , 请修改 docker-compose.yml 文件中对应的端口
# 访问 URL , 按照实际 <IP:端口> , <域名>进行修改 , 需要保证这个地址可以访问到部署的 Web 服务 , 参考案例如下：
# URL=http://your-domain.com/
URL=http://${HOSTNAME_IP}:8000/

# 内置存储服务 相关配置 , MINIO_ROOT_PASSWORD , 首次安装系统会自动生成随机字符串填入 , MINIO_SERVER_URL 为 api 接口 , MINIO_BROWSER_REDIRECT_URL 为 web 界面：
MINIO_SERVER_URL=http://${HOSTNAME_IP}:9000/
MINIO_BROWSER_REDIRECT_URL=http://${HOSTNAME_IP}:9001/
MINIO_ROOT_USER=datarc
MINIO_ROOT_PASSWORD=
MINIO_BUCKET=datarc

# 对象存储 S3 协议 相关配置
# 北极数据 在线版本 , 默认使用 北极数据自带存储服务 , 默认存储桶为 datarc , 如需使用外部文件文件上传功能 , 以下两种均可实现：
# 1. 需提供一个 支持 S3 协议的存储桶如（腾讯云COS，阿里云 OSS）, 并设置 S3 相关参数
# 2. 将 内置存储服务 MINIO_SERVER_URL , MINIO_BROWSER_REDIRECT_URL Nginx 转发 , 并填写为 https 域名 , S3_ENDPOINT 填写 MINIO_SERVER_URL 的参数 , 也可以提供标准 S3 服务
S3_ENDPOINT=http://${HOSTNAME_IP}:9000/
S3_SECRET_ID=datarc
S3_SECRET_KEY=
S3_REGION=datarc
S3_BUCKET=datarc

# PostgreSQL 相关配置
POSTGRES_USER=postgres
POSTGRES_PASSWORD=example
POSTGRES_DB=postgres
PGDATA=/var/lib/postgresql/data

# 服务镜像 , 更新时请正确设置成对应版本号
CORE_IMAGE=dockerhub.qingcloud.com/datarc/core:v${image_version}
WS_IMAGE=dockerhub.qingcloud.com/datarc/go-ws:latest

# 其他设置 , 无需修改
GIN_MODE=release
PRODUCTION=true
C_FORCE_ROOT=true
EOF

  minio_user=$(cat ${path}/.env | grep MINIO_ROOT_USER= | awk -F"[ = ]" '{print $2}')
  minio_passwd=$(tr </dev/urandom -dc '12345!@#qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c32)
  grep -w MINIO_ROOT_PASSWORD= ${path}/.env 1>/dev/null 2>&1
  if [ $? -eq 0 ]; then
    sed -i "s%MINIO_ROOT_PASSWORD=%MINIO_ROOT_PASSWORD=$minio_passwd%g" ${path}/.env
    sed -i "s%S3_SECRET_KEY=%S3_SECRET_KEY=$minio_passwd%g" ${path}/.env
  fi
  minio_password=$(cat ${path}/.env | grep MINIO_ROOT_PASSWORD= | awk -F"[ = ]" '{print $2}')

  echo_info "------ 正在拉取编排文件 ------   \n"
  cat >${path}/docker-compose.yml <<'EOF'
version: '3.5'

services:
  postgres:
    image: postgres:13-alpine
    restart: always
    env_file: .env
    volumes:
      - ./data/pg_data:/var/lib/postgresql/data
  redis:
    image: redis:6-alpine
    restart: always
    command: [ "redis-server", "--save", '""', "--appendonly", "no" ]
  clickhouse:
    image: yandex/clickhouse-server
    restart: always
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
    volumes:
      - ./data/ch-data:/var/lib/clickhouse
  go-ws:
    image: "${WS_IMAGE}"
    restart: always
    env_file: .env
  minio:
    image: quay.io/minio/minio
    restart: always
    env_file: .env
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - ./data/minio-data:/data
    command: server /data --console-address ":9001"      
  web:
    image: "${CORE_IMAGE}"
    restart: always
    env_file: .env
    volumes:
      - ./configs.py:/home/code/jiaogong/configs.py
    depends_on:
      - postgres
      - redis
      - go-ws
    ports:
      - 8000:8000
    command: "gunicorn jiaogong.wsgi -c gunicorn.conf.py"
  beat:
    image: "${CORE_IMAGE}"
    restart: always
    depends_on:
      - postgres
      - redis
    env_file: .env
    volumes:
      - ./configs.py:/home/code/jiaogong/configs.py
    command: "celery --app=jiaogong beat --loglevel=INFO"
  worker:
    image: "${CORE_IMAGE}"
    restart: always
    depends_on:
      - postgres
      - redis
    env_file: .env
    volumes:
      - ./configs.py:/home/code/jiaogong/configs.py
    command: "celery --app=jiaogong worker --loglevel=INFO --concurrency=5 --events --queues=celery"
EOF

  cd ${path} && wget -O datarc.sh https://r.datarc.cn/deploy/${datarc_verion}/install_online.sh

  sed -i "6s%datarc_dir=%datarc_dir=${path}%" ${path}/datarc.sh
  (chmod +x ${path}/datarc.sh && cp ${path}/datarc.sh /usr/bin/datarc)
  datarc start
  echo_info "------ MinIO 账号：${minio_user} 密码：${minio_password} "
  echo_info "------ 北极数据服务安装完成，安装目录为 ${path}，如需更改配置，请修改后，执行 datarc restart 重启服务------ \n"
}

################################### 初始化
function initialize() {
  BUCKET=$(cat ${datarc_dir}/.env | grep MINIO_BUCKET | awk -F"[ = ]" '{print $2}')
  BUCKET_dir=$(grep minio-data ${datarc_dir}/docker-compose.yml | awk -F"[ . - :]+" '{print $3}')
  if [ ! -d "${datarc_dir}${BUCKET_dir}/${BUCKET}" ]; then
    (mkdir -p ${datarc_dir}${BUCKET_dir}/${BUCKET})
  fi
  minio_user=$(cat ${datarc_dir}/.env | grep MINIO_ROOT_USER= | awk -F"[ = ]" '{print $2}')
  minio_passwd=$(tr </dev/urandom -dc '12345!@#qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c32)
  grep -w MINIO_ROOT_PASSWORD= ${datarc_dir}/.env
  if [ $? -eq 0 ]; then
    sed -i "s%MINIO_ROOT_PASSWORD=%MINIO_ROOT_PASSWORD=$minio_passwd%g" ${datarc_dir}/.env
    sed -i "s%S3_SECRET_KEY=%S3_SECRET_KEY=$minio_passwd%g" ${datarc_dir}/.env
  fi
  echo ""
  HOSTNAME_IP=$(hostname -I | awk '{print $1}')

  (cp ${datarc_dir}/datarc.sh /usr/bin/datarc)
}

###################################  restart
function restart {
  echo_info "------ 启动北极数据服务 ------ \n"
  cd "${datarc_dir}" && docker-compose up -d --remove-orphans --force-recreate
}

################################### stop
function stop {
  echo_info "------ 正在停止 北极数据服务 请稍等 ------ \n"
  cd "${datarc_dir}" && docker-compose stop
}

################################### update
function update() {
  echo_info "准备更新镜像..."
  cd ${datarc_dir} && docker-compose pull
  echo_info "重新启动服务..."
  cd ${datarc_dir} && docker-compose up -d --remove-orphans --force-recreate
  echo_info "执行清理工作..."
  cd ${datarc_dir} && docker system prune --force
  echo_info "更新完成..."

}

################################### help
function help() {
  echo "$(gettext 'Arctic data Deployment Management Script')"
  echo
  echo "Usage: "
  echo "  datarc [COMMAND] [ARGS...]"
  echo "  datarc --help"
  echo "  bash datarc.sh --help"
  echo
  echo "Installation Commands: "
  echo " *install           $(gettext 'Install Arctic data')"
  echo
  echo "Management Commands: "
  echo " *start             $(gettext 'Start   Arctic data')"
  echo "  stop              $(gettext 'Stop    Arctic data')"
  echo " *restart           $(gettext 'Restart Arctic data')"
  echo "  update            $(gettext 'Update  Arctic data')"
  echo

}
function main() {
  case "$1" in
  install)
    install
    ;;
  start)
    restart
    initialize
    restart
    ;;
  restart)
    initialize
    restart
    ;;
  stop)
    stop
    ;;
  update)
    update
    ;;
  help)
    help
    ;;
  --help)
    help
    ;;
  -h)
    help
    ;;
  *)
    echo "No such command: $1"
    help
    ;;
  esac
}
main "$@"
