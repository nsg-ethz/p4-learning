sudo cp p4_16-mode.el /usr/share/emacs/site-lisp/
sudo mkdir -p /home/edgar/.emacs.d/
echo "(autoload 'p4_16-mode' \"p4_16-mode.el\" \"P4 Syntax.\" t)" > init.el
echo "(add-to-list 'auto-mode-alist '(\"\\.p4\\'\" . p4_16-mode))" | tee -a init.el
sudo mv init.el /home/edgar/.emacs.d/
sudo ln -s /usr/share/emacs/site-lisp/p4_16-mode.el /home/edgar/.emacs.d/p4_16-mode.el
sudo chown -R edgar:edgar /home/edgar/.emacs.d/
