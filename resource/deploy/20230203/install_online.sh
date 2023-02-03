#!/bin/bash
# 执行命令 bash install_online.sh --path=<路径> --username=<用户名> --password=<密码> --core_version=<X.X.X> --ws_version=<X.X.X> 
# 说明 --username --password 为必填值
###############  --path  可设置参数 ############################################
datarc_verion=20230203
WEB_PORT=8000
MINIO_PORT=9000
# datarc_dir 用于设置程序的安装目录。取消注释后正确设置。
# datarc_dir=
function main() {
  ARGS=$(getArgs "$@")
  path=$(echo "$ARGS" | getNamedArg path) ; [ ! $path ] && path='/opt/datarc'
  username=$(echo "$ARGS" | getNamedArg username)
  password=$(echo "$ARGS" | getNamedArg password)
  core_version=$(echo "$ARGS" | getNamedArg core_version) ; [ ! $core_version ] && core_version='2.32.2'
  ws_version=$(echo "$ARGS" | getNamedArg ws_version) ; [ ! $ws_version ] && ws_version='1.0.2'
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
  echo '=================================================================================================='
  echo -en "\033[1;32m""\033[3m$1 \033[0m\033[87G \033[1;32m\033[3m [ SUCCES ] \033[0m\n"
}

function echo_warning() {
  echo '=================================================================================================='
  echo -en "\033[1;33m""\033[3m$1 \033[0m\033[86G \033[1;33m\033[3m [ WARNING ] \033[0m\n"
}

function echo_error() {
  echo '=================================================================================================='
  echo -en "\033[1;31m""\033[3m$1 \033[0m\033[88G \033[1;31m\033[3m [ ERROR ] \033[0m\n"
  exit 1
}


###############  开始安装服务   ############################################
HOSTNAME_IP=$(hostname -I | awk '{print $1}')
function install() {
  echo_info "------ 开始安装北极九章服务 ------ \n"
  if [ "$(id -u)" -ne "0" ]; then
    echo "请使用 root 权限执行安装脚本"
    exit 1
  fi

###############  开始安装 docker   ############################################
 function get_docker_install() {
    (wget -O get-docker.sh https://gitee.com/ldsink/toolbox/raw/master/get-docker.sh && chmod +x get-docker.sh && ./get-docker.sh --mirror Aliyun && systemctl start docker && systemctl enable docker)
  }
  
 function check_docker_install() {
    echo_info "------ 开始检查该系统是否安装 docker 服务 ------ "
    if [ -x "$(command -v 'docker')" ]; then
      echo_info "------ 检测到该系统已安装 docker 服务，尝试启动 docker 服务 ------"
      systemctl start docker 2>/dev/null || service docker start 2>/dev/null
      [ ! -z "$(docker ps 2>/dev/null)" ] || (
        echo_warning "------ docker 服务启动失败、正在为您重新安装 docker 服务 ------"
        get_docker_install
      )

      [ ! -z "$(docker ps 2>/dev/null)" ] && echo_info "------ docker 服务已经安装成功 ------" || echo_error "------ docker 服务安装失败、您的系统暂时无法安装 docker 服务------"

    else
      echo_warning "------ 检测到该系统没有安装 docker 服务、尝试安装 docker 服务 ------"
      get_docker_install

      [ ! -z "$(docker ps 2>/dev/null)" ] && echo_info "------ docker 服务已经安装成功 ------" || echo_error "------ docker 服务安装失败、您的系统暂时无法安装 docker 服务 ------"
    fi
  }

  check_docker_install
  
  
  if [ ! -x "$(command -v docker-compose)" ]; then
    echo_info "------ 尝试安装 docker-compose 服务------ "
    # version=1.29.2
    # 官方原链接 curl -L https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose  
    (wget -O docker-compose https://r.datarc.cn/deploy/docker-compose && mv docker-compose /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose)
  else
    echo_info "------ 检测到该系统已安装 docker-compose 服务------ "
  fi

###############  登录 docker   ############################################
  echo_info "------ 正在登录私有仓库中 ------   \n"
  docker login --username=$username --password=$password swr.cn-north-9.myhuaweicloud.com

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
# 将文中 127.0.0.1 替换为 实际 <IP> , <域名> , 端口如果被占用 , 请修改 可用端口
# 访问 URL , 按照实际 <IP:端口> , <域名>进行修改 , 需要保证这个地址可以访问到部署的 Web 服务 , 参考案例如下：
# URL=http://your-domain.com/
URL=http://${HOSTNAME_IP}:${WEB_PORT}/

# 内置存储服务 相关配置 , MINIO_ROOT_PASSWORD , 首次安装系统会自动生成随机字符串填入 , MINIO_SERVER_URL 为 api 接口： 
MINIO_SERVER_URL=http://${HOSTNAME_IP}:${MINIO_PORT}/
MINIO_ROOT_USER=datarc
MINIO_ROOT_PASSWORD=
MINIO_BUCKET=datarc

# 对象存储 S3 协议 相关配置
# 北极九章 在线版本 , 默认使用 北极九章自带存储服务 , 默认存储桶为 datarc , 如需使用外部文件文件上传功能 , 以下两种均可实现：
# 1. 需提供一个 支持 S3 协议的存储桶如（腾讯云COS，阿里云 OSS）, 并设置 S3 相关参数
# 2. 将 内置存储服务 MINIO_SERVER_URL Nginx 转发 , 并填写为 https 域名 , S3_ENDPOINT 填写 MINIO_SERVER_URL 的参数 , 也可以提供标准 S3 服务
S3_ENDPOINT=http://${HOSTNAME_IP}:${MINIO_PORT}/
S3_SECRET_ID=datarc
S3_SECRET_KEY=
S3_REGION=datarc
S3_BUCKET=datarc

# PostgreSQL 相关配置
POSTGRES_USER=postgres
POSTGRES_PASSWORD=example
POSTGRES_DB=postgres
PGDATA=/var/lib/postgresql/data

# 端口冲突时请修改
WEB_PORT=8000
MINIO_PORT=9000

# 服务镜像 , 更新时请正确设置成对应版本号
CORE_VERSION=core:v${core_version}
WS_VERSION=go-ws:v${ws_version}

# 其他设置 , 无需修改
REPO_URL=swr.cn-north-9.myhuaweicloud.com/datarc/
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
    image: "${REPO_URL}postgres:15-alpine"
    restart: always
    env_file: .env
    privileged: true
    volumes:
      - ./data/pg15_data:/var/lib/postgresql/data
    command: postgres -c 'max_connections=1000'
  redis:
    image: "${REPO_URL}redis:6-alpine"
    restart: always
    command: [ "redis-server", "--save", '""', "--appendonly", "no" ]
  clickhouse:
    image: "${REPO_URL}clickhouse-server:22.8.9.24-alpine"
    restart: always
    privileged: true
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
    volumes:
      - ./data/ch-data:/var/lib/clickhouse
  go-ws:
    image: "${REPO_URL}${WS_VERSION}"
    restart: always
    env_file: .env
    depends_on:
      - minio
  minio:
    image: "${REPO_URL}minio:22.8"
    restart: always
    env_file: .env
    privileged: true
    ports:
      - ${MINIO_PORT}:9000
    volumes:
      - ./data/minio-data:/data
    command: server /data 
  web:
    image: "${REPO_URL}${CORE_VERSION}"
    restart: always
    env_file: .env
    volumes:
      - ./configs.py:/home/code/jiaogong/configs.py
    depends_on:
      - postgres
      - redis
      - go-ws
      - clickhouse
    ports:
      - ${WEB_PORT}:8000
    command: "gunicorn jiaogong.wsgi -c gunicorn.conf.py"
  beat:
    image: "${REPO_URL}${CORE_VERSION}"
    restart: always
    depends_on:
      - postgres
      - redis
      - go-ws
    env_file: .env
    volumes:
      - ./configs.py:/home/code/jiaogong/configs.py
    command: "celery --app=jiaogong beat --loglevel=INFO"
  worker:
    image: "${REPO_URL}${CORE_VERSION}"
    restart: always
    depends_on:
      - postgres
      - redis
      - clickhouse
    env_file: .env
    volumes:
      - ./configs.py:/home/code/jiaogong/configs.py
    command: "celery --app=jiaogong worker --loglevel=INFO --concurrency=5 --events --queues=celery"
EOF

  cd ${path} && wget -O datarc.sh https://r.datarc.cn/deploy/${datarc_verion}/install_online.sh
  sed -i "s%# datarc_dir=%datarc_dir=${path}%" ${path}/datarc.sh
  (chmod +x ${path}/datarc.sh && cp ${path}/datarc.sh /usr/bin/datarc)
  datarc start
  echo_info "------ MinIO 账号：${minio_user} 密码：${minio_password} "
  echo_info "------ 北极九章服务安装完成，安装目录为 ${path}，如需更改配置，请修改后，执行 datarc restart 重启服务------ \n"
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
  echo_info "------ 启动北极九章服务 ------ \n"
  cd "${datarc_dir}" && docker-compose up -d --remove-orphans --force-recreate
}

################################### stop
function stop {
  echo_info "------ 正在停止 北极九章服务 请稍等 ------ \n"
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
