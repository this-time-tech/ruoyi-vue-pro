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

  #启动容器
  docker compose -f ./script/docker/docker-compose.yaml up -d

}

main() {
  environment_check
  download_code
  deploy_code
}

main