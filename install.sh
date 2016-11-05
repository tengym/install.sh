#!/bin/sh

setup_fstab()
{
    mount | grep work && return

    if [ ! -e /dev/sdb ];then
        echo "没有work磁盘，请重新安装work磁盘"
        exit 1
    fi
    if [ ! -e /dev/sdb1 ];then
        sfdisk -D /dev/sdb << EOF
,,0x82,*
,,,-
EOF
        sfdisk -R /dev/sdb
        sleep 1
        mkfs.ext4 /dev/sdb1 -L work
    fi

    mkdir -p /work
    fstab_string="LABEL=work /work auto defaults 0 1"
    sed '/LABEL/d' /etc/fstab
    if ! grep "$fstab_string" /etc/fstab;then
        e2label /dev/sdb1 work
        echo $fstab_string >> /etc/fstab
    fi
    mount /work
}

setup_samba()
{
    pdbedit -L $SUDO_USER && return 0
    echo "
[global]
   workgroup = Workgroup
   server string = $SUDO_USER Linux Virtualbox
   dns proxy = no
   security = user
   map to guest = bad user
[work]
   path = /work
   comment = work
   browseable = yes
   read only = no
   create mask = 0777
   directory mask = 0777

   " > /etc/samba/smb.conf 
   echo "输入 你的 samba 用户： $SUDO_USER 的密码:"
   smbpasswd -a $SUDO_USER
   /etc/init.d/smbd restart
}

install_soft()
{
    apt-get update 
    if [ $? != 0 ];then
        echo "更新失败，请检查你的网络配置!"
        exit 1
    fi

	if [ ! -e /tmp/.upgrade ];then
		apt-get upgrade -y
		touch /tmp/.upgrade
	fi

	apt-get install -y realpath 
	apt-get install -y rsync 
    apt-get install -y sqlite sqlitebrowser
	apt-get install -y geany
	apt-get install -y nfs-common
	apt-get install -y openssh-server
	apt-get install -y vim vim-gtk vim-doc
	apt-get install -y ctags cscope 
	apt-get install -y cgvg 
	apt-get install -y sloccount
	apt-get install -y apparix
	apt-get install -y make
	apt-get install -y samba
	apt-get install -y tftpd-hpa tftp telnet
	apt-get install -y nfs-kernel-server
	apt-get install -y gcc gdb g++ valgrind expect
    apt-get install -y fakeroot
	apt-get install -y linux-headers-$(uname -r)

	apt-get install -y fcitx im-config
	#apt-get install -y qt4-default qt4-doc qtcreator
	apt-get install -y meld xarchiver p7zip-full
    
    apt-get install -y libncurses5-dev

    apt-get install -y u-boot-tools
    apt-get install -y subversion git rapidsvn tig
    apt-get install -y qemu-system-arm
}

setup_tftpd()
{
	mkdir -p /work/tftp
    chmod 777 /work/tftp
    if [ -e /etc/default/tftpd-hpa ];then
        sed -i 's#TFTP_DIRECTORY=.*#TFTP_DIRECTORY="/work/tftp"#g' /etc/default/tftpd-hpa
    else
        dpkg-reconfigure tftpd-hpa
    fi
    /etc/init.d/tftpd-hpa restart
}

setup_nfs()
{
	mkdir -p /work/nfs
	chmod 755 /work/
	chmod 777 /work/nfs
    echo "/work/nfs *(rw,nohide,insecure,no_subtree_check,async,no_root_squash)" > /etc/exports
    /etc/init.d/nfs-kernel-server restart
}

install_soft
setup_fstab
setup_samba
setup_tftpd
setup_nfs
