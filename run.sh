#!/bin/bash
#20250401
#fred

download_admin_code() {
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

download_app_code() {
  #检查目标目录master是否存在
  if [ -d "./yudao-ui/yudao-mall-uniapp/master" ]; then
    echo "目标目录已存在，跳过创建"
  else
    echo "目标目录不存在，创建中..."
    #建立一个目录
    mkdir -p ./yudao-ui/yudao-mall-uniapp/master

    #进入目录
    cd ./yudao-ui/yudao-mall-uniapp/master

    #下载代码
    git clone https://github.com/this-time-tech/yudao-mall-uniapp

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
  # 检查 yudao-server 是否存在，存在则删除
  if docker images -q yudao-server > /dev/null; then
    echo "清理原有镜像，准备重新构建"
    docker rmi -f yudao-server
  fi

  # 检查 yudao-admin 是否存在，存在则删除
  if docker images -q yudao-admin > /dev/null; then
    echo "清理原有镜像，准备重新构建"
    docker rmi -f yudao-admin
  fi

  # 检查 yudao-mall-uniapp 是否存在，存在则删除
  if docker images -q yudao-mall-uniapp > /dev/null; then
    echo "清理原有镜像，准备重新构建"
    docker rmi -f yudao-mall-uniapp
  fi

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
  if ! docker node ls | grep "Ready"; then
    echo "Docker Swarm is not active, initializing swarm..."
    docker swarm init
    # 获取所有节点的 ID 和 Manager 状态，并通过 grep 找到 Leader 节点
    LEADER_NODE_ID=$(docker node ls --format '{{.ID}} {{.ManagerStatus}}' | grep 'Leader' | awk '{print $1}')

    # 检查是否找到了 Leader 节点
    if [ -z "$LEADER_NODE_ID" ]; then
      echo "没有找到 Leader 节点"
      exit 1
    fi

    # 给 Leader 节点添加标签
    docker node update --label-add role=server $LEADER_NODE_ID
    # 验证标签是否添加成功
    LABELS=$(docker node inspect $LEADER_NODE_ID --format '{{.Spec.Labels}}')

    # 检查是否成功添加了 role=server 标签
    if echo "$LABELS" | grep "role:server"; then
      echo "成功为节点 $LEADER_NODE_ID 添加标签 role=server"
    else
      echo "未能为节点 $LEADER_NODE_ID 添加标签 role=server。请手动添加标签以启动服务"
    fi
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
    download_admin_code
    download_app_code
    deploy_code
  fi
}

main
