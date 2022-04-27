#!/usr/bin/env bash
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
#action=${1}
tmp_directory="/tmp/datarc"
datarc_dir=/opt/datarc

function install() {
   echo_info "------ 开始安装北极数据服务 ------ \n"
if [ "$(id -u)" -ne "0" ]; then
  echo_warning "------ 请使用 root 权限执行安装脚本 ------ \n"
  exit 1
fi

if [ ! -f "datarc.sh" ]; then
  echo_error "------ 未找到北极数据安装文件 ------ \n"
  exit 1
fi
   echo_info "------ 准备北极数据安装文件 ------ \n"
if [ -d "${tmp_directory}" ]; then
  echo_info "------ 删除以前的安装文件 ------ \n"
  rm -rf "${tmp_directory}"
fi
mkdir "${tmp_directory}"
cp "docker-compose" "${tmp_directory}"
cp "image.tar.gz" "${tmp_directory}"
file_list=("config.tar.gz" "docker.tar.gz")
for file in "${file_list[@]}"; do
  tar -zxf "${file}" --directory "${tmp_directory}"
done
if [ ! -x "$(command -v docker)" ]; then
  echo_info "------ 系统尚未安装 docker 程序，即将开始安装 docker ------ \n"
  docker_file_dir="${tmp_directory}/docker"
  if [ ! -d "${docker_file_dir}" ]; then
    echo_error "------ 未找到 docker 安装文件 ------ \n"
    exit 1
  fi

  echo_info "------ 开始安装 docker 服务 ------ \n"
  Get_Dist_Name() {
    if grep -Eqii "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
      DISTRO='CentOS'
      PM='yum'
      echo_info "------ 正在判断系统 ------ \n\n 这是 CentOS 系统、正在安装 docker 服务 \n"
      (cd "${docker_file_dir}" && yum -y localinstall *.rpm)

    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
      DISTRO='RHEL'
      PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
      DISTRO='Aliyun'
      PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
      DISTRO='Fedora'
      PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
      DISTRO='Debian'
      PM='apt'
      echo_info "------ 正在判断系统 ------ \n\n 这是 Debian 系统、正在安装 docker 服务 \n"
      dpkg -i "${docker_file_dir}/docker-scan-plugin_0.8.0~debian-buster_amd64.deb" "${docker_file_dir}/containerd.io_1.4.6-1_amd64.deb" "${docker_file_dir}/docker-ce_20.10.7~3-0~debian-buster_amd64.deb" "${docker_file_dir}/docker-ce-cli_20.10.7~3-0~debian-buster_amd64.deb" "${docker_file_dir}/docker-ce-rootless-extras_20.10.7~3-0~debian-buster_amd64.deb"

    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
      DISTRO='Ubuntu'
      PM='apt'
      echo_info "------ 正在判断系统 ------ \n\n 这是 Ubuntu 系统、正在安装 docker 服务 \n"
      dpkg -i "${docker_file_dir}/docker-scan-plugin_0.8.0~ubuntu-focal_amd64.deb" "${docker_file_dir}/containerd.io_1.4.6-1_amd64.deb" "${docker_file_dir}/docker-ce_20.10.7~3-0~ubuntu-focal_amd64.deb" "${docker_file_dir}/docker-ce-cli_20.10.7~3-0~ubuntu-focal_amd64.deb" "${docker_file_dir}/docker-ce-rootless-extras_20.10.7~3-0~ubuntu-focal_amd64.deb"
 elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
      DISTRO='Raspbian'
      PM='apt'
    else
      DISTRO='unknow'
    fi
  }
  Get_Dist_Name

###############  检测 docker 是否安装成功   ############################################
if [ -x "$(command -v docker)" ]; then
    echo_info "------  docker 服务安装成功 ------ \n"
  fi

  echo_info "------ 启动 docker 服务并设置开机自启 ------ \n"
  systemctl start docker && systemctl enable docker
fi

if [ ! -x "$(command -v docker-compose)" ]; then
  echo_info "------ 启动 docker-compose ------ \n"
  mv "${tmp_directory}/docker-compose" /usr/local/bin/
  chmod +x /usr/local/bin/docker-compose
else
  echo_info "------ 系统已安装 docker-compose ------ \n"
fi

echo_info "------ 加载北极服务镜像文件 ------ \n"
image_file="${tmp_directory}/image.tar.gz"
if [ ! -f "${image_file}" ]; then
  echo_error "------ 未找到北极服务镜像文件 ------ \n"
  exit 1
fi
docker load --input "${image_file}"
echo_info "------ 镜像文件加载成功 ------ \n"
echo "安装北极数据服务，安装目录为 ${datarc_dir}"
config_dir="${tmp_directory}/config"
if [ ! -d "${config_dir}" ]; then
  echo_info "------ 未找到初始配置文件 ------ \n"
  exit 1
fi

echo_info "------ 检查初始配置文件 ------ \n"
if [ ! -f "${datarc_dir}/licence.key" ]; then
  if [ -f "licence.key" ]; then
    cp "licence.key" "${config_dir}"
  fi
fi

if [ ! -f "${datarc_dir}/configs.py" ]; then
  if [ -f "configs.py" ]; then
    cp "configs.py" "${config_dir}"
  fi
fi

if [ ! -f "${datarc_dir}/datarc.sh" ]; then
  if [ -f "datarc.sh" ]; then
    cp "datarc.sh" "${config_dir}"
  fi
fi

config_files=("docker-compose.yml" ".env" "configs.py")
for config_file in "${config_files[@]}"; do
  if [ ! -f "${config_dir}/${config_file}" ]; then
    echo "未找到文件 ${config_file}，忽略..."
  fi
done

echo "复制初始配置文件到目录 ${datarc_dir}"
if [ ! -d "${datarc_dir}" ]; then
  mkdir -p "${datarc_dir}"
fi

cp -r -n "${config_dir}"/. "${datarc_dir}/"

minio_user=`cat ${datarc_dir}/.env|grep MINIO_ROOT_USER=|awk -F"[ = ]" '{print $2}'`
minio_passwd=`</dev/urandom tr -dc '12345!@#qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c32;`
grep -w MINIO_ROOT_PASSWORD= ${datarc_dir}/.env 1>/dev/null 2>&1
if [ $? -eq 0 ];then
  sed -i "s%MINIO_ROOT_PASSWORD=%MINIO_ROOT_PASSWORD=$minio_passwd%g" ${datarc_dir}/.env
  sed -i "s%S3_SECRET_KEY=%S3_SECRET_KEY=$minio_passwd%g" ${datarc_dir}/.env
fi
minio_password=`cat ${datarc_dir}/.env|grep MINIO_ROOT_PASSWORD=|awk -F"[ = ]" '{print $2}'`
echo_info "------ MinIO 账号：${minio_user} 密码：${minio_password} "
echo ""

echo_info "------ 清理安装过程中产生的临时文件 ------ \n"
rm -rf "${tmp_directory}"

echo_info "------ 北极数据服务安装完成，安装目录为 ${datarc_dir}，修改 .env 正确参数，执行 datarc start 开启服务------ \n"
(cp ${datarc_dir}/datarc.sh /usr/bin/datarc)
################################### 初始化
}
function initialize() {
BUCKET=`cat ${datarc_dir}/.env|grep MINIO_BUCKET|awk -F"[ = ]" '{print $2}'`
BUCKET_dir=`grep minio-data ${datarc_dir}/docker-compose.yml |awk -F"[ . - :]+" '{print $3}'`
if [ ! -d "${datarc_dir}${BUCKET_dir}/${BUCKET}" ]; then
	(mkdir -p ${datarc_dir}${BUCKET_dir}/${BUCKET})
fi
minio_user=`cat ${datarc_dir}/.env|grep MINIO_ROOT_USER=|awk -F"[ = ]" '{print $2}'`
minio_passwd=`</dev/urandom tr -dc '12345!@#qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c32;`
grep -w MINIO_ROOT_PASSWORD= ${datarc_dir}/.env
if [ $? -eq 0 ];then
  sed -i "s%MINIO_ROOT_PASSWORD=%MINIO_ROOT_PASSWORD=$minio_passwd%g" ${datarc_dir}/.env
  sed -i "s%S3_SECRET_KEY=%S3_SECRET_KEY=$minio_passwd%g" ${datarc_dir}/.env
fi
echo ""
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
if [ ! -f "${datarc_dir}/image.tar.gz" ]; then
    echo_error "------ 将镜像文件移动至 ${datarc_dir} 目录 ------ \n"
    exit 1
else
    stop
    echo_info "------ 正在更新 北极数据服务 请稍等 ------ \n"
    docker load --input "image.tar.gz"
    echo_info "------  北极数据镜像 加载成功 请稍后 ------ \n"
fi
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

function main(){
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
    initialize
    update
    restart
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
