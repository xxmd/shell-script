# 确保 /etc/trojan-go/ 目录下 config.json 配置文件，全链证书和key文件存在
docker run \
    --name trojan-go-port \
    -d \
   -p port:443 \
    -v /etc/trojan-go/:/etc/trojan-go \
    p4gefau1t/trojan-go