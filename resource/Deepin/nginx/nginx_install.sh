####### 设置源
cat >> /etc/apt/sources.list.d/nginx.list  << "EOF"
deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx
deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx
EOF
####### Nginx 官方公钥认证
wget https://r.datarc.cn/Deepin/nginx/nginx_signing.key && apt-key add nginx_signing.key
####### 解决依赖
wget https://r.datarc.cn/Deepin/nginx/libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb && dpkg -i libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb
####### 安装 nginx
sudo apt update && sudo apt install nginx -y
