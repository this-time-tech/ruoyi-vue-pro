#!/bin/bash
#20250401
#fred

download_code() {
  #检查目标目录master是否存在
  if [ -d "./yudao-ui/yudao-ui-admin-vue3/master" ]; then
    echo "目标目录已存在，跳过创建"
  else
    echo "目标目录不存在，创建中..."
    #建立一个目录
    mkdir -p ./yudao-ui/yudao-ui-admin-vue3/master

    #进入目录
    cd ./yudao-ui/yudao-ui-admin-vue3/master

    #下载代码
    git clone https://github.com/this-time-tech/yudao-ui-admin-vue3

    #回到当前目录
    cd ../../..
  fi
}

environment_check() {
  #检查是否存在git, docker。不存在则安装
  if ! command -v git &>/dev/null; then
    echo "git could not be found, installing..."
    sudo apt-get install git -y
  else
    echo "git is already installed"
  fi
  if ! command -v docker &>/dev/null; then
    echo "docker could not be found, installing..."
    curl -fsSL https://get.docker.com -o install-docker.sh
    sudo sh install-docker.sh --mirror Aliyun
  else
    echo "docker is already installed"
  fi
}

deploy_code() {
  #检查docker是否安装
  if ! command -v docker &>/dev/null; then
    echo "docker could not be found, please install docker first"
    exit 1
  fi
  #清理原有镜像
  docker rmi -f yudao-server
  docker rmi -f yudao-admin
  #复制文件
  cp ./script/docker/docker-compose.yaml ./docker-compose.yaml
  #启动容器
  docker compose up -d
  echo "Deploy finished -- 部署完毕"
  rm -rf ./docker-compose.yaml
}

# 集群部署
deploy_cluster() {
  #检查docker是否安装
  if ! command -v docker &>/dev/null; then
    echo "docker could not be found, please install docker first"
    exit 1
  fi
  #检查docker swarm是否启用
  if ! docker info | grep -q "Swarm: active"; then
    echo "Docker Swarm is not active, initializing swarm..."
    docker swarm init
  else
    echo "Docker Swarm is already active"
  fi
  #  - node.labels.role == server
  #检查节点是否存在
  if ! docker node ls | grep -q "yudao-server"; then
    echo "Node yudao-server does not exist, creating..."
    docker node create --label role=server yudao-server
  else
    echo "Node yudao-server already exists"
  fi
  #复制文件
  cp ./script/docker/docker-compose-cluster.yaml ./docker-compose.yaml
  #启动容器
  docker stack deploy -c docker-compose.yaml yudao-system-cluster
  echo "Deploy finished -- 部署完毕"
  rm -rf ./docker-compose.yaml
}

main() {
  # 询问用户是否集群部署，还是单机部署
  read -p "Deploy in a cluster?--是否集群部署？(y/n): " choice
  if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    deploy_cluster
  else
    environment_check
    download_code
    deploy_code
  fi
}

main
