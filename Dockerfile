# docker build -t rlliang/php70 .

# docker run -d -e "NGINX_GENERATE_DEFAULT_VHOST=false" --dns=202.192.0.20 --add-host dataexgp.wfuzz.com:192.168.10.152 --add-host gp.wfuzz.com:192.168.10.152 --add-host www.phpmyadmin.com:192.168.10.149 --add-host api.wfuzz.com:192.3.36.150 --privileged=true --read-only=false --ulimit nofile=102400:102400 -p 127.0.0.1:2253:22 -p 80:80 -p 443:443 -p 1080:1080 -p 8080:8080 -v /opt/docker/php70/logs:/var/log/nginx -v /opt/docker/php70/www:/www -v /opt/docker/php70/conf:/etc/nginx/ext.d -h php70 --name=php70 rlliang/php70

# docker run -d -e "NGINX_GENERATE_DEFAULT_VHOST=false" --dns=202.192.0.20 --add-host dataexgp.wfuzz.com:192.168.10.152 --add-host gp.wfuzz.com:192.168.10.147 --add-host www.phpmyadmin.com:192.168.10.147 --add-host api.wfuzz.com:192.3.36.147 --privileged=true --read-only=false --ulimit nofile=102400:102400 -p 127.0.0.1:2253:22 -p 80:80 -p 443:443 -p 1080:1080 -p 8080:8080 -v /opt/docker/php70/logs:/var/log/nginx -v /opt/docker/php70/www:/www -v /opt/docker/php70/conf:/etc/nginx/ext.d -h php70 --name=php70 rlliang/php70


FROM docker.io/centos:latest
MAINTAINER rlliang <huzailingcom@gmail.com>

RUN yum clean all
RUN yum install -y yum-plugin-fastestmirror yum-utils epel-release
RUN yum update -y

# utils
RUN yum install -y git hostname sudo less iproute psmisc net-tools \
bash unzip which tar passwd ed m4 patch rsync wget curl tcpdump telnet \
tar bzip2 unzip strace supervisor openssl openssh openssh-server \
openssh-clients util-linux inotify-tools 

# dev
RUN yum install -y gcc-c++ libtool make gdb mariadb-devel snappy-devel \
boost-devel lz4-devel zlib-devel libcurl-devel libevent-devel \
libesmtp-devel libuuid-devel libcsv-devel cyrus-sasl-devel \
bzip2-devel libpqxx-devel libxml2-devel libxslt-devel libxslt-python \
libpng-devel jemalloc-devel fontconfig-devel pcre-devel

# deps
RUN yum install -y redis sqlite mariadb mariadb-server postgresql

# python
RUN yum install -y python-pip python-devel python-lxml python-setuptools 

RUN mkdir /var/run/sshd
RUN ssh-keygen -t rsa -q -f /etc/ssh/ssh_host_rsa_key -P ""
RUN ssh-keygen -t dsa -q -f /etc/ssh/ssh_host_dsa_key -P ""
RUN ssh-keygen -t rsa -q -f /root/.ssh/id_rsa -P ""
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys

RUN echo 'root:pwd' | chpasswd 
RUN sed -i 's/.*session.*required.*pam_loginuid.so.*/session optional pam_loginuid.so/g' /etc/pam.d/sshd
RUN echo -e "LANG=\"en_US.UTF-8\"" > /etc/default/local
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
RUN cp /usr/lib64/mysql/libmysqlclient* /usr/lib64/
RUN rm -rf etc/localtime && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN echo "bind '\"\e[A\":history-search-backward'" >> /root/.bashrc
RUN echo "bind '\"\e[B\":history-search-forward'" >> /root/.bashrc
RUN echo "export HISTTIMEFORMAT='%F %T '" >> /root/.bashrc

EXPOSE 22 
RUN chmod u+s /usr/bin/ping

# node
RUN yum install -y nodejs npm

# misc
RUN yum install -y GraphicsMagick

ADD container-files/etc/yum.repos.d/nginx.repo /etc/yum.repos.d/

RUN \
    yum install -y nginx && \
    groupmod --gid 80 --new-name www nginx && \
    usermod --uid 80 --home /www --gid 80 --login www --shell /bin/bash --comment www nginx && \
    rm -rf /etc/nginx/*.d /etc/nginx/*_params && \
    mkdir -p /etc/nginx/certs && \
    openssl genrsa -out /etc/nginx/certs/dummy.key 2048 && \
    openssl req -new -key /etc/nginx/certs/dummy.key -out /etc/nginx/certs/dummy.csr -subj "/C=GB/L=London/O=Company Ltd/CN=docker" && \
    openssl x509 -req -days 3650 -in /etc/nginx/certs/dummy.csr -signkey /etc/nginx/certs/dummy.key -out /etc/nginx/certs/dummy.crt

RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm && \
    yum-config-manager -q --enable remi && \
    yum-config-manager -q --enable remi-php70 && \
    yum install -y php-fpm php-cli php-mcrypt php-mysql php-gd php-ldap php-odbc php-pdo php-pecl-memcache php-pear php-mbstring php-xml php-xmlrpc php-snmp php-soap php-zipstream php-pgsql php-bcmath php-intl php-opcache php-pecl-zip && \
    yum install -y --disablerepo=epel php-pecl-redis php-pecl-yaml

RUN npm config set strict-ssl false && npm config set registry http://registry.cnpmjs.org

ADD composer /usr/bin/composer

RUN npm update -g npm && \
    npm install -g gulp grunt-cli bower browser-sync && \
    echo -e "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
    chmod 755 /usr/bin/composer && chown www /usr/bin/composer

ENV \
  NGINX_GENERATE_DEFAULT_VHOST=false \
  STATUS_PAGE_ALLOWED_IP=127.0.0.1

ADD ./nginx_reload.sh /bin/
RUN chmod 755 /bin/nginx_reload.sh

EXPOSE 80 443 1080 8080

RUN mkdir -p /etc/nginx/ext.d
VOLUME ["/www"]
VOLUME ["/etc/nginx/ext.d"]
VOLUME ["/var/log/nginx"]  

RUN yum clean all

ADD container-files /

RUN chmod +x /config/bootstrap.sh
RUN chmod +x /config/init/*.sh

ENTRYPOINT ["/config/bootstrap.sh"]


