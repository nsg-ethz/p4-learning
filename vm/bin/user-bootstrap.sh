#!/usr/bin/env bash

set -xe

#Installs all the editors and set gui applications
bash /vagrant/bin/gui-apps.sh

#Install Extra Networking Tools and Helpers
bash /vagrant/bin/misc-install.sh

# Install P4lang tools
bash /vagrant/bin/install-p4-tools.sh
