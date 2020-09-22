#!/bin/bash

# Print commands and exit on errors
set -xe

#Install Generic Dependencies and Programs

apt-get update

KERNEL=$(uname -r)
DEBIAN_FRONTEND=noninteractive sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
sudo apt-get install -y --no-install-recommends \
  autoconf \
  automake \
  bison \
  build-essential \
  ca-certificates \
  cmake \
  cpp \
  curl \
  emacs nano\
  flex \
  git \
  git-review \
  libboost-dev \
  libboost-filesystem-dev \
  libboost-iostreams1.58-dev \
  libboost-program-options-dev \
  libboost-system-dev \
  libboost-thread-dev \
  libc6-dev \
  libevent-dev \
  libffi-dev \
  libfl-dev \
  libgc-dev \
  libgc1c2 \
  libgflags-dev \
  libgmp-dev \
  libgmp10 \
  libgmpxx4ldbl \
  libjudy-dev \
  libpcap-dev \
  libreadline6 \
  libreadline6-dev \
  libssl-dev \
  libtool \
  linux-headers-$KERNEL\
  lubuntu-desktop \
  make \
  mktemp \
  pkg-config \
  python \
  python-dev \
  python-ipaddr \
  python-setuptools \
  tcpdump \
  zip unzip \
  vim \
  wget \
  xcscope-el \
  xterm \
  htop \
  arping \
  gawk \
  iptables \
  libprotobuf-c-dev \
  g++ \
  bash-completion \
  traceroute


#Install pip from source
apt-get purge python-pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py

#python libraries
pip install ipaddress

# debugging
pip install ipython ipdb

#add swap memory
bash /vagrant/bin/add_swap_memory.sh

# Disable passwordless ssh
bash /vagrant/bin/ssh_ask_password.sh

#create user p4
useradd -m -d /home/p4 -s /bin/bash p4
echo "p4:p4" | chpasswd
echo "p4 ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_p4
chmod 440 /etc/sudoers.d/99_p4
usermod -aG vboxsf p4
update-locale LC_ALL="en_US.UTF-8"

#set wallpaper
cd /usr/share/lubuntu/wallpapers/
cp /home/vagrant/nsg-logo.png .
rm lubuntu-default-wallpaper.png
ln -s nsg-logo.png lubuntu-default-wallpaper.png
rm /home/vagrant/nsg-logo.png
cd /home/vagrant
sed -i s@#background=@background=/usr/share/lubuntu/wallpapers/1604-lubuntu-default-wallpaper.png@ /etc/lightdm/lightdm-gtk-greeter.conf


# Disable screensaver
apt-get -y remove light-locker

# Automatically log into the P4 user
cat << EOF | tee -a /etc/lightdm/lightdm.conf.d/10-lightdm.conf
[SeatDefaults]
autologin-user=p4
autologin-user-timeout=0
user-session=Lubuntu
EOF

su p4 <<'EOF'
cd /home/p4
bash /vagrant/bin/user-bootstrap.sh
EOF

# make sure all files in /home/p4 are owned by user p4
chown -R p4:p4 /home/p4/

# Change Vagrant password. Otherwise if deployed in the wild it can be a vulnerability
# Alternative would be to make vagrant and root users only sshable with a key
echo "vagrant:gv82NEudNnp$w87[" | sudo chpasswd

# Do this last!
reboot
