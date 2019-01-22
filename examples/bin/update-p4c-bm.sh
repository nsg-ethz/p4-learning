#! /bin/bash

#change directory to the directory where p4-bmv2 is

#assumes that bmv2 is installed here:
cd $HOME/p4/p4c-bm

git pull
sudo pip install -r requirements.txt
sudo python setup.py install
cd ..
