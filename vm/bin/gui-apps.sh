#!/usr/bin/env bash

# Installs Lubuntu desktop and code editors.
# Largely inspired by the P4.org tutorial VM scripts:
# https://github.com/p4lang/tutorials/

set -xe

#sublime
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo add-apt-repository ppa:webupd8team/atom -y
sudo apt-get update

#Installs wireshark skiping the inte
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install wireshark
echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure wireshark-common

sudo apt-get -y --no-install-recommends install \
    lubuntu-desktop \
    atom \
    sublime-text \
    vim \
    wget



# Emacs
sudo mv /home/vagrant/p4_16-mode.el /usr/share/emacs/site-lisp/
sudo mkdir /home/p4/.emacs.d/
echo "(autoload 'p4_16-mode' \"p4_16-mode.el\" \"P4 Syntax.\" t)" > init.el
echo "(add-to-list 'auto-mode-alist '(\"\\.p4\\'\" . p4_16-mode))" | tee -a init.el
sudo mv init.el /home/p4/.emacs.d/
sudo ln -s /usr/share/emacs/site-lisp/p4_16-mode.el /home/p4/.emacs.d/p4_16-mode.el
sudo chown -R p4:p4 /home/p4/.emacs.d/

# Vim
cd /home/p4
mkdir -p .vim
mkdir -p .vim/ftdetect
mkdir -p .vim/syntax
echo "au BufRead,BufNewFile *.p4      set filetype=p4" >> .vim/ftdetect/p4.vim
echo "set bg=dark" >> .vimrc
sudo mv /home/vagrant/p4.vim .vim/syntax/

# Sublime
cd /home/p4
mkdir -p ~/.config/sublime-text-3/Packages/
cd .config/sublime-text-3/Packages/
git clone https://github.com/c3m3gyanesh/p4-syntax-highlighter.git

# Atom
apm install language-p4

# Adding Desktop icons
DESKTOP=/home/p4/Desktop
mkdir -p ${DESKTOP}

cat > ${DESKTOP}/Terminal << EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
Name=Terminal
Name[en_US]=Terminal
Icon=konsole
Exec=/usr/bin/x-terminal-emulator
Comment[en_US]=
EOF

cat > ${DESKTOP}/Wireshark << EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
Name=Wireshark
Name[en_US]=Wireshark
Icon=wireshark
Exec=/usr/bin/wireshark
Comment[en_US]=
EOF

cat > ${DESKTOP}/Sublime\ Text << EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
Name=Sublime Text
Name[en_US]=Sublime Text
Icon=sublime-text
Exec=/opt/sublime_text/sublime_text
Comment[en_US]=
EOF

cat > ${DESKTOP}/Atom << EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
Name=Atom
Name[en_US]=Atom
Icon=atom
Exec=/usr/bin/atom
Comment[en_US]=
EOF
