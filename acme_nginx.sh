#!/bin/bash
set -e

# ===================== 配置项（仅邮箱可预设）=====================
MAIL="xxmd3720@gmail.com"
# =========================================================================

echo "==================== 开始部署 Nginx + ACME.SH 自动SSL证书 ===================="

# 强制手动输入域名，无默认值
read -p "请输入需要申请证书的域名: " DOMAIN
if [ -z "${DOMAIN}" ]; then
    echo "错误：域名不能为空！"
    exit 1
fi
echo "已设置域名: ${DOMAIN}"

# 1. 安装 acme.sh
echo -e "\n[1/7] 安装 acme.sh 证书工具"
curl https://get.acme.sh | sh -s email="${MAIL}"

# 生效 acme.sh 别名
source /root/.bashrc
ACME_SH="/root/.acme.sh/acme.sh"

# 2. 安装 Nginx
echo -e "\n[2/7] 安装 Nginx"
yum install -y nginx

# 3. 创建证书目录并加固权限
echo -e "\n[3/7] 创建证书存放目录"
mkdir -p /etc/pki/nginx/private
chmod 700 /etc/pki/nginx/private

# 4. 停止Nginx，使用 standalone 模式申请 SSL 证书
echo -e "\n[4/7] 开始申请 SSL 证书"
systemctl stop nginx || true
${ACME_SH} --issue --standalone -d "${DOMAIN}"

# 5. 部署证书 + 配置自动续期重载Nginx
echo -e "\n[5/7] 部署证书并配置自动续期"
${ACME_SH} --install-cert -d "${DOMAIN}" \
--key-file       /etc/pki/nginx/private/server.key  \
--fullchain-file /etc/pki/nginx/server.crt \
--reloadcmd     "systemctl reload nginx"

# 6. 写入 Nginx 配置（80跳转443 + SSL）
echo -e "\n[6/7] 写入 Nginx 主配置文件"
cat > /etc/nginx/nginx.conf << EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    # 80 端口强制 301 跳转 HTTPS
    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        return 301 https://\$host\$request_uri;
    }

    # 443 SSL 站点配置
    server {
        listen       443 ssl http2;
        listen       [::]:443 ssl http2;
        server_name  _;
        root         /usr/share/nginx/html;

        ssl_certificate "/etc/pki/nginx/server.crt";
        ssl_certificate_key "/etc/pki/nginx/private/server.key";
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout  10m;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
        location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }
}
EOF

# 校验 Nginx 配置
echo -e "\n校验 Nginx 配置语法..."
nginx -t

# 开机自启并启动 Nginx
echo -e "\n启动 Nginx 并设置开机自启"
systemctl enable nginx
systemctl start nginx

echo -e "\n==================== 部署完成 ===================="
echo "访问测试：http://${DOMAIN} 自动跳转 https://${DOMAIN}"
echo "证书已配置自动续期，无需手动操作"
