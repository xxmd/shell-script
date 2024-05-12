#!/bin/bash

echo "移除gost相关文件"
rm -rf gost-linux-amd64-*

gost_version="3.0.0-rc.0"
echo "下载 gost 源代码，版本 ${gost_version}"
# https://github.com/go-gost/gost/releases/download/v3.0.0-rc.0/gost-linux-amd64v3-3.0.0-rc.0.gz
wget "https://github.com/go-gost/gost/releases/download/v${gost_version}/gost-linux-amd64-${gost_version}.gz"

echo "下载解压工具"
yum install -y gzip

echo "解压 gost 源码压缩包"
gzip -d gost-linux-amd64-${gost_version}.gz


#pid=`ps -ef | grep gost | grep -v 'grep' | awk '{print $2}'`
#if [ -n "$pid" ]
#then
#	echo "杀死其他 gost 进程，进程 id 为 $pid"
#	kill -9 $pid
#fi

echo "添加 gost 可执行命令"
mv -f gost-linux-amd64-${gost_version} /usr/bin/gost
chmod +x /usr/bin/gost

check_domain() {
    local domain=$1

    # 检查域名格式
    if ! [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}错误：域名格式不正确${NC}"
        return 1
    fi

    return 0
}

# 域名配置
while true; do
    echo -e "${GREEN}请输入一个有效的域名：${NC}"
    read domain

    # 调用检测域名格式的函数
    check_domain "$domain"
    if [ $? -ne 0 ]; then
        continue
    else
        break
    fi
done

echo "输入的域名是：$domain"


echo "生成gost配置文件"
mkdir /etc/gost
touch /etc/gost/config.yaml
echo "
services:
- name: service-0
  addr: ":4000"
  handler:
    type: http
  listener:
    type: tls
- name: service-1
  addr: ":4001"
  handler:
    type: http
  listener:
    type: tls
- name: service-2
  addr: ":4002"
  handler:
    type: http
  listener:
    type: tls
tls:
  certFile: "/root/.acme.sh/${domain}_ecc/fullchain.cer"
  keyFile: "/root/.acme.sh/${domain}_ecc/${domain}.key"
" > /etc/gost/config.yaml


echo "添加 gost 服务"
echo "[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/bin/gost -C /etc/gost/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/gost.service


echo "刷新 service"
systemctl daemon-reload

echo "设置代理服务开机自启"
systemctl enable gost.service

echo "启动代理服务"
systemctl start gost.service

echo "代理服务启动状态如下，看到绿色的 'active(runing)' 字符证明服务启动成功"
systemctl status gost.service