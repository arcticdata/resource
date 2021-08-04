#!/usr/bin/env bash
#--------------------------------------------
# 更新北极数据相关服务
#
# wget -O update.sh https://r.datarc.cn/deploy/update.sh && sh update.sh
#
#--------------------------------------------

compose_file="docker-compose.yml"
current_dir="${PWD##*/}"

pull_images() {
  echo "准备更新镜像..."
  docker-compose pull
}

restart_services() {
  echo "重新启动服务..."
  docker-compose up -d --remove-orphans --force-recreate
}

migrate_query_service() {
  if [ "$(docker ps -q -f name=${current_dir}_query_web_1)" ]; then
    echo "迁移查询服务数据库..."
    docker exec -it "${current_dir}_query_web_1" pipenv run python manage.py migrate
  else
    echo "未检测到查询服务"
  fi
}

migrate_core_service() {
  if [ "$(docker ps -q -f name=${current_dir}_core_web_1)" ]; then
    echo "迁移核心服务数据库..."
    docker exec -it "${current_dir}_core_web_1" pipenv run python manage.py migrate
  else
    echo "未检测到核心服务"
  fi
}

clean_images() {
  echo "执行清理工作..."
  docker system prune --force
}

if [ -e $compose_file ]; then
  pull_images
  restart_services
  migrate_query_service
  migrate_core_service
  clean_images
  echo "更新完成"
else
  echo "编排文件 docker-compose.yml 不存在，请将本脚本放在编排文件同级目录下"
  exit 1
fi
