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
echo_info "------ 开始安装北极数据服务 ------ \n"

if [ "$(id -u)" -ne "0" ]; then
  echo_warning "------ 请使用 root 权限执行安装脚本 ------ \n"
  exit 1
fi

if [ ! -f "install.sh" ]; then
  echo_error "------ 未找到北极数据安装文件 ------ \n"
  exit 1
fi

echo_info "------ 准备北极数据安装文件 ------ \n"
tmp_directory="/tmp/datarc"
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

datarc_dir="/opt/datarc"
echo "安装北极数据服务，安装目录为 ${datarc_dir}"
config_dir="${tmp_directory}/config"
if [ ! -d "${config_dir}" ]; then
  echo_info "------ 未找到初始配置文件 ------ \n"
  exit 1
fi

echo_info "------ 检查初始配置文件 ------ \n"
cp "licence.key" "${config_dir}"
config_files=("update.sh" "docker-compose.yml" ".env" "configs.py" "licence.key")
for config_file in "${config_files[@]}"; do
  if [ ! -f "${config_dir}/${config_file}" ]; then
    echo "未找到文件 ${config_file}，忽略..."
  fi
done

echo "复制初始配置文件到目录 ${datarc_dir}"
if [ ! -d "${datarc_dir}" ]; then
  mkdir "${datarc_dir}"
fi
cp -r -n "${config_dir}"/. "${datarc_dir}/"

echo_info "------ 清理安装过程中产生的临时文件 ------ \n"
rm -rf "${tmp_directory}"

echo_info "------ 北极数据服务安装完成 ------ \n"

function execute_update_script {
  echo_info "------ 执行更新脚本 ------ \n"
  (cd "${datarc_dir}" && ./update.sh)
}

function execute_update_commands {
  echo_info "------ 开始启动北极数据服务 ------ \n"
  docker-compose up -d --remove-orphans --force-recreate

  cd "${datarc_dir}" || exit 1

  if [ "$(docker ps -q -f name=datarc_web_1)" ]; then
    echo_info "------ 迁移服务数据库 ------ \n"
    docker exec -it datarc_web_1 pipenv run python manage.py migrate
  else
    echo_error "------ 未检测到服务容器 ------ \n"
  fi

  echo_info "------ 重启北极数据服务 ------ \n"
  docker-compose up -d --remove-orphans --force-recreate
}

echo_info "------ 启动北极数据服务 ------ \n"
if [ ! -f "${datarc_dir}/update.sh" ]; then
  (cd "${datarc_dir}" && execute_update_commands)
else
  (cd "${datarc_dir}" && execute_update_script)
fi

function initialize() {
  echo_info "如果您是初次安装，请前往 ${datarc_dir} 目录下："
  echo ""
  echo_info "执行如下命令，从授权文件命令初始化客户数据："
  echo_info "docker exec -it datarc_web_1 pipenv run python manage.py initialize --create-default-admin"
  echo ""
}

initialize
