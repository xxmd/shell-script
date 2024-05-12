#/bin/bash
check_domain() {
    # 检查域名格式
    if ! [[ "$1" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "错误：域名格式不正确"
        return 1
    fi
    return 0
}

domain=$1
if [ -z "${domain}" ]; then
    echo "错误：未提供域名参数"
    read -p "请输入一个有效的域名：" domain
fi

while true; do
  check_domain "$domain"
      if [ $? -ne 0 ]; then
          read -p "请输入一个有效的域名：" domain
      else
          break
      fi
done
echo "输入的域名是：$domain"

curl https://get.acme.sh | sh -s email=my@example.com
export Ali_Key="LTAI5tFPT65zKFjGMgUkLuUd"
export Ali_Secret="tmpb6r7nnbEE8VgfKwmRHzlKZKL1Lb"
ln -s /root/.acme.sh/acme.sh
acme.sh --issue --dns dns_ali -d ${domain} --force