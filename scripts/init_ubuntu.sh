#/bin/bash
#######################################################
#                                                     #
#       Author    : Liwu Dong                         #
#       Email     : i@dongliwu.com                    #
#       Blog      : https://dongliwu.com              #
#       Data      : 2018-08-21                        #
#       Reference : Teddysun (https://teddysun.com)   #
#                                                     #
#######################################################

#set -e
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CLEAN='\033[0m'

[[ ! -n `cat /proc/version | grep ubuntu` ]]  && echo -e "[${RED}Error${CLEAN}] Not Ubuntu, Exit..." && exit 1

[[ $EUID -ne 0 ]] && echo -e "[${RED}Error${CLEAN}] This script must be run as root!" && exit 1

cat << EOF
+---------------------------------------------------------------+
|                                                               |
|                    Welcome to Ubuntu init                     |
|                                  By: Liwu Dong                |
|                                                               |
+---------------------------------------------------------------+
EOF

function depends_install(){
   local command=$1
   local depend=`echo "${command}" | awk '{print $4}'`
   echo -e "[${GREEN}Info${CLEAN}] Installing package ${depend}"
   ${command} > /dev/null 2>&1
   if [ $? -ne 0 ]; then
       echo -e "[${RED}Error${CLEAN}] Failed to install ${RED}${depend}${CLEAN}"
       exit 1
   fi
}

# tools
echo -e "$BLUE ------------------ install tools ----------------------- $CLEAN"
echo -e "[${GREEN}Info${CLEAN}] Updating repository..."
CODE_NAME=`lsb_release -c --short`
cp /etc/apt/sources.list /etc/apt/sources.list.`date +%s`
cat > /etc/apt/sources.list << EOF
deb http://mirrors.aliyun.com/ubuntu/ ${CODE_NAME} main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ ${CODE_NAME}-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ ${CODE_NAME}-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ ${CODE_NAME}-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ ${CODE_NAME}-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${CODE_NAME} main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${CODE_NAME}-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${CODE_NAME}-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${CODE_NAME}-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${CODE_NAME}-backports main restricted universe multiverse
EOF
apt-get update > /dev/null 2>&1
if [ $? -eq 0 ]; then
   echo -e "[${GREEN}Info${CLEAN}] Update repository completed"
else
   echo -e "[${RED}Error${CLEAN}] Update repository failed"
   exit 1
fi

apt_depends=(
   vim git wget make ntp fontconfig tmux python-pip openssh-server
)
for depend in ${apt_depends[@]}
do
   depends_install "apt-get install -y $depend"
done

# ssh
echo -e "$BLUE ----------------------- sshd --------------------------- $CLEAN"
sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config
sed -i "s/MaxAuthTries 3/MaxAuthTries 3/g" /etc/ssh/sshd_config
service ssh restart

# crontab
echo -e "$BLUE ---------------------- crontab ------------------------- $CLEAN"
(crontab -l ; echo "00	04	*	*	*	/bin/sync; /bin/echo 3 > /proc/sys/vm/drop_caches") | crontab
(crontab -l ; echo "00	02	*	*	*	/usr/sbin/ntpdate ntp.aliyun.com > /dev/null 2>&1 ") | crontab
crontab -l

# vim
echo -e "$BLUE ------------------------ vim --------------------------- $CLEAN"
pip install git+git://github.com/powerline/powerline
wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
mv PowerlineSymbols.otf /usr/share/fonts/
mv 10-powerline-symbols.conf /etc/fonts/conf.d/
pl_location=`pip show powerline-status| grep Location | awk '{print $2}'`

cat >> /etc/vim/vimrc << EOF

" Custom by Lyon
set rtp+=${pl_location}/powerline/bindings/vim/
set laststatus=2
set t_Co=256
set nu
set ts=4
set sw=4
EOF

# bash
echo -e "$BLUE ------------------------ bash -------------------------- $CLEAN"
cp -rf ../etc/bashrc-ps /etc/
sed -i '$a\source\ \/etc\/bashrc-ps' /etc/skel/.bashrc
sed -i '$a\source\ \/etc\/bashrc-ps' /root/.bashrc
sed -i '$a\source\ \/etc\/bashrc-ps' ~/.bashrc

# tmux
echo -e "$BLUE ------------------------ tmux -------------------------- $CLEAN"
cat > /etc/tmux.conf << EOF
source ${pl_location}/powerline/bindings/tmux/powerline.conf
EOF

# ulimit
echo -e "$BLUE ----------------------- ulimit ------------------------- $CLEAN"
cat > /etc/security/limits.d/90-nproc.conf << EOF
* soft nproc 655360
* hard nproc 655360
EOF
cat > /etc/security/limits.d/90-nofile.conf << EOF
* soft nofile 655360
* hard nofile 655360
EOF

ulimit -SHn 655360

# sysctl
echo -e "$BLUE ---------------------- sysctl ------------------------- $CLEAN"
cat > /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_max_tw_buckets = 10000
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
EOF

sysctl -p


echo -e "$BLUE ------------------------ end --------------------------- $CLEAN"
echo  "Please run the command:"
echo ""
echo -e "$GREEN          source ~/.bashrc $CLEAN"
echo ""
