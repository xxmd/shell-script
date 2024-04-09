#!/bin/bash
# receive args
domain_name=$1
kill_process_using_port() {
    local port=$1
    local pid=$(sudo netstat -tunlp | awk -v port="$port" '$4 ~ ":"port && $6 == "LISTEN" { split($7, arr, "/"); print arr[1] }')
    echo $pid
    if [ -n "$pid" ]; then
        sudo kill -9 $pid
        echo "Process using port $port killed"
    else
        echo "No process found using port $port"
    fi
}

# 查找并杀死占用 80 端口的程序
kill_process_using_port 80

# 查找并杀死占用 443 端口的程序
kill_process_using_port 443

#rm -rf trojan*

# download trojan-go
#wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip
#yum install unzip -y
#unzip trojan-go-linux-amd64.zip

# request cert from domain
#curl https://get.acme.sh | sh -s email=xxmd3720@gmail.com
#yum install socat -y 
#sudo ls -s /root/.acme.sh/acme.sh /usr/local/bin/
#acme.sh --issue --standalone -d ${domain_name}

# make link and copy server config file
ln -s -f /root/trojan-go /usr/bin
chmod 777 /usr/bin/trojan-go
server_config_file="/etc/trojan-go/config.json"
touch $server_config_file
echo -n > $server_config_file
cp -f /root/example/server.json $server_config_file

# modify server_config_file
sed -i "s/\"cert\": \".*\"/\"cert\": \"\/root\/.acme.sh\/${domain_name}_ecc\/fullchain.cer\"/" $server_config_file
sed -i "s/\"key\": \".*\"/\"key\": \"\/root\/.acme.sh\/${domain_name}_ecc\/${domain_name}.key\"/" $server_config_file
sed -i "s/\"sni\": \".*\"/\"sni\": \"${domain_name}\"/" $server_config_file
sed -i "s/\"enabled\": true/\"enabled\": false/" $server_config_file

# install and start nginx
#yum install nginx -y
#systemctl start nginx

# trojan-go service
cp -f /root/example/trojan-go.service /etc/systemd/system/

sed -i "s/User=nobody/User=root/" /etc/systemd/system/trojan-go.service
systemctl daemon-reload
systemctl start trojan-go.service
systemctl status trojan-go.service


