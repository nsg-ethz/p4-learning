#! /bin/bash

#save current path to return later
CURRENT_PATH="$(pwd)"

cd $HOME/p4/p4c

# Recommended in p4c's README.md
git submodule update --init --recursive

# Get updates from master repo
git pull

if [ -d build ]
then
    echo "Deleting build directory"
    /bin/rm -fr build
fi

echo "Building p4c from scratch"
mkdir build
cd build

# Configure for a debug build
cmake .. -DCMAKE_BUILD_TYPE=DEBUG 
make -j 4
sudo make install

#if needed
#copy custom v1model.p4
if [[ $* == *--update-v1model* ]]
then
    cd "$CURRENT_PATH"
    cp ../docs/includes/v1model.p4 /usr/local/share/p4c/p4include/
fi