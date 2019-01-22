#!/bin/bash


#Install Dependencies (ubuntu 16.04 is recommended. In ubuntu 14.04 some dependencies have to be installed manually)

apt-get install -y \
  git \
  mininet \
  autoconf \
  automake \
  libtool \
  curl \
  make \
  g++ \
  unzip \
  libgc-dev \
  bison \
  flex \
  libfl-dev \
  libgmp-dev \
  libboost-dev \
  libboost-iostreams-dev \
  pkg-config \
  python \
  python-scapy \
  python-ipaddr \
  tcpdump \
  cmake

#create directory p4 (if it does not exist) in home. And cd

mkdir -p $HOME/p4
cd $HOME/p4

# Bmv2
git clone https://github.com/p4lang/behavioral-model bmv2
cd bmv2
./install_deps.sh
./autogen.sh
./configure
make
sudo make install
sudo ldconfig
cd ..

#P4C-bmv2 (old compiler, deprecated soon?)
git clone https://github.com/p4lang/p4c-bm.git
cd p4c-bm
sudo pip install -r requirements.txt
sudo python setup.py install
cd ..

# Protobuf
git clone https://github.com/google/protobuf.git
cd protobuf
git checkout v3.2.0
./autogen.sh
./configure
make
sudo make install
sudo ldconfig
cd ..

# libboost 1.57 is required

wget boost_1_58_0.tar.gz http://sourceforge.net/projects/boost/files/boost/1.58.0/boost_1_58_0.tar.gz/download
tar xzvf boost_1_57_0.tar.gz
cd boost_1_58_0/

./bootstrap.sh --prefix=/usr/local
user_configFile=`find $PWD -name user-config.jam`
echo "using mpi ;" >> $user_configFile

sudo ./b2 --with=all -j 4 install 

sudo sh -c 'echo "/usr/local/lib" >> /etc/ld.so.conf.d/local.conf'
sudo ldconfig

# P4C
git clone --recursive https://github.com/p4lang/p4c
cd p4c
mkdir build
cd build
#only if cmake < 3.0.2
#sudo apt-get install software-properties-common
#sudo add-apt-repository ppa:george-edison55/cmake-3.x
#sudo apt-get update
#sudo apt-get install --only-upgrade cmake
cmake ..
make -j4
sudo make install
cd ..
cd ..
