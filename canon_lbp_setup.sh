#!/bin/bash

##################################################
#Version 3.3 updated on September 13, 2019
#http://help.ubuntu.ru/wiki/canon_capt
#http://forum.ubuntu.ru/index.php?topic=189049.0
#Translated into English and modified by @hieplpvip
#Việt hóa và chỉnh sửa bởi @linhdhvn
##################################################

#Check if we are running as root
[ $USER != 'root' ] && exec sudo "$0"

#Current user
LOGIN_USER=$(logname)
[ -z "$LOGIN_USER" ] && LOGIN_USER=$(who | head -1 | awk '{print $1}')

#Load the file containing the path to the desktop
if [ -f ~/.config/user-dirs.dirs ]; then
	source ~/.config/user-dirs.dirs
else
	XDG_DESKTOP_DIR="$HOME/Desktop"
fi

#Driver version
DRIVER_VERSION='2.71-1'
DRIVER_VERSION_COMMON='3.21-1'

#Links to driver packages
declare -A URL_DRIVER=([amd64_common]='https://github.com/linhdhvn/canon_printer/raw/master/Packages/cndrvcups-common_3.21-1_amd64.deb' \
[amd64_capt]='https://github.com/linhdhvn/canon_printer/raw/master/Packages/cndrvcups-capt_2.71-1_amd64.deb' \
[i386_common]='https://github.com/linhdhvn/canon_printer/raw/master/Packages/cndrvcups-common_3.21-1_i386.deb' \
[i386_capt]='https://github.com/linhdhvn/canon_printer/raw/master/Packages/cndrvcups-capt_2.71-1_i386.deb')

#Links to autoshutdowntool
declare -A URL_ASDT=([amd64]='https://github.com/linhdhvn/canon_printer/raw/master/Packages/autoshutdowntool_1.00-1_amd64_deb.tar.gz' \
[i386]='https://github.com/linhdhvn/canon_printer/raw/master/Packages/autoshutdowntool_1.00-1_i386_deb.tar.gz')

#ppd files and printer models mapping
declare -A LASERSHOT=([LBP-810]=1120 [LBP1120]=1120 [LBP1210]=1210 \
[LBP2900]=2900 [LBP3000]=3000 [LBP3010]=3050 [LBP3018]=3050 [LBP3050]=3050 \
[LBP3100]=3150 [LBP3108]=3150 [LBP3150]=3150 [LBP3200]=3200 [LBP3210]=3210 \
[LBP3250]=3250 [LBP3300]=3300 [LBP3310]=3310 [LBP3500]=3500 [LBP5000]=5000 \
[LBP5050]=5050 [LBP5100]=5100 [LBP5300]=5300 [LBP6000]=6018 [LBP6018]=6018 \
[LBP6020]=6020 [LBP6020B]=6020 [LBP6200]=6200 [LBP6300n]=6300n [LBP6300]=6300 \
[LBP6310]=6310 [LBP7010C]=7018C [LBP7018C]=7018C [LBP7200C]=7200C [LBP7210C]=7210C \
[LBP9100C]=9100C [LBP9200C]=9200C)

#Sort printer names
NAMESPRINTERS=$(echo "${!LASERSHOT[@]}" | tr ' ' '\n' | sort -n -k1.4)

#Models supported by autoshutdowntool
declare -A ASDT_SUPPORTED_MODELS=([LBP6020]='MTNA002001 MTNA999999' \
[LBP6020B]='MTMA002001 MTMA999999' [LBP6200]='MTPA00001 MTPA99999' \
[LBP6310]='MTLA002001 MTLA999999' [LBP7010C]='MTQA00001 MTQA99999' \
[LBP7018C]='MTRA00001 MTRA99999' [LBP7210C]='MTKA002001 MTKA999999')

#OS architecture
if [ "$(uname -m)" == 'x86_64' ]; then
	ARCH='amd64'

	# Check and add i386 architecture for 64-bit systems
    if [ "$(dpkg --print-foreign-architectures)" == 'i386' ]; then
	    echo "Kiến trúc i386 đã được thêm vào hệ thống"
    else
        dpkg --add-architecture i386
    fi
else
	ARCH='i386'
fi

#Determine the init system
if [[ $(ps -p1 | grep systemd) ]]; then
	INIT_SYSTEM='systemd'
else
	INIT_SYSTEM='upstart'
fi

#Move to the current directory
cd "$(dirname "$0")"

function valid_ip() {
	local ip=$1
	local stat=1

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		ip=($(echo "$ip" | tr '.' ' '))
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat=$?
	fi
	return $stat
}

function check_error() {
	if [ $2 -ne 0 ]; then
		case $1 in
			'WGET') echo "Lỗi khi tải file $3"
				[ -n "$3" ] && [ -f "$3" ] && rm "$3";;
			'PACKAGE') echo "Lỗi khi cài đặt gói $3";;
			*) echo 'Đã xảy ra lỗi';;
		esac
		echo 'Nhấn phím bất kỳ để thoát'
		read -s -n1
		exit 1
	fi
}

function canon_uninstall() {
	if [ -f /usr/sbin/ccpdadmin ]; then
		installed_model=$(ccpdadmin | grep LBP | awk '{print $3}')
		if [ -n "$installed_model" ]; then
			echo "Đã tìm thấy máy in $installed_model"
			echo "Đang đóng trình theo dõi trạng thái máy in"
			killall captstatusui 2> /dev/null
			echo 'Đang dừng dịch vụ ccpd'
			service ccpd stop
			echo 'Đang xóa máy in khỏi cấu hình dịch vụ ccpd'
			ccpdadmin -x $installed_model
			echo 'Đang xóa máy in khỏi CUPS'
			lpadmin -x $installed_model
		fi
	fi
	echo 'Đang xóa các gói driver'
	dpkg --purge cndrvcups-capt
	dpkg --purge cndrvcups-common
	echo 'Đang xóa các thư viện và gói không còn sử dụng'
	apt-get -y autoremove
	echo 'Đang xóa các thiết lập'
	[ -f /etc/init/ccpd-start.conf ] && rm /etc/init/ccpd-start.conf
	[ -f /etc/udev/rules.d/85-canon-capt.rules ] && rm /etc/udev/rules.d/85-canon-capt.rules
	[ -f "${XDG_DESKTOP_DIR}/captstatusui.desktop" ] && rm "${XDG_DESKTOP_DIR}/captstatusui.desktop"
	[ -f /usr/bin/autoshutdowntool ] && rm /usr/bin/autoshutdowntool
	[ $INIT_SYSTEM == 'systemd' ] && update-rc.d -f ccpd remove
	echo 'Đã gỡ cài đặt xong'
	echo 'Nhấn phím bất kỳ để thoát'
	read -s -n1
	return 0
}

function canon_install() {
	echo
	PS3='Hãy chọn máy in: '
	select NAMEPRINTER in $NAMESPRINTERS
	do
		[ -n "$NAMEPRINTER" ] && break
	done
	echo "Máy in đã chọn: $NAMEPRINTER"
	echo
	PS3='Máy in được kết nối với máy tính bằng cách nào? '
	select CONECTION in 'Qua USB' 'Qua mạng (LAN, NET)'
	do
		if [ "$REPLY" == "1" ]; then
			CONECTION="usb"
			while true
			do
				#Looking for a device connected to the USB port
				NODE_DEVICE=$(ls -1t /dev/usb/lp* 2> /dev/null | head -1)
				if [ -n "$NODE_DEVICE" ]; then
					#Find the serial number of that device
					PRINTER_SERIAL=$(udevadm info --attribute-walk --name=$NODE_DEVICE | sed '/./{H;$!d;};x;/ATTRS{product}=="Canon CAPT USB \(Device\|Printer\)"/!d;' | awk -F'==' '/ATTRS{serial}/{print $2}')
					#If the serial number is found, that device is a Canon printer
					[ -n "$PRINTER_SERIAL" ] && break
				fi
				echo -ne "Hãy bật máy in và cắm cáp USB\r"
				sleep 2
			done
			PATH_DEVICE="/dev/canon$NAMEPRINTER"
			break
		elif [ "$REPLY" == "2" ]; then
			CONECTION="lan"
			read -p 'Nhập địa chỉ IP của máy in: ' IP_ADDRES
			until valid_ip "$IP_ADDRES"
			do
				echo 'Địa chỉ IP không đúng định dạng. Hãy nhập lại'
				echo -n 'từ 0 đến 255, ngăn cách bằng dấu chấm: '
				read IP_ADDRES
			done
			PATH_DEVICE="net:$IP_ADDRES"
			echo 'Hãy bật máy in rồi nhấn phím bất kỳ'
			read -s -n1
			sleep 5
			break
		fi
	done
	echo '************CÀI ĐẶT DRIVER************'
	COMMON_FILE=cndrvcups-common_${DRIVER_VERSION_COMMON}_${ARCH}.deb
	CAPT_FILE=cndrvcups-capt_${DRIVER_VERSION}_${ARCH}.deb
	if [ ! -f $COMMON_FILE ]; then
		sudo -u $LOGIN_USER wget -O $COMMON_FILE ${URL_DRIVER[${ARCH}_common]}
		check_error WGET $? $COMMON_FILE
	fi
	if [ ! -f $CAPT_FILE ]; then
		sudo -u $LOGIN_USER wget -O $CAPT_FILE ${URL_DRIVER[${ARCH}_capt]}
		check_error WGET $? $CAPT_FILE
	fi
	apt-get -y update
	apt-get -y install libglade2-0 libcanberra-gtk-module
	check_error PACKAGE $?
	echo 'Đang cài đặt thành phần dùng chung cho driver CUPS'
	dpkg -i $COMMON_FILE
	check_error PACKAGE $? $COMMON_FILE
	echo 'Đang cài đặt thành phần driver máy in CAPT'
	dpkg -i $CAPT_FILE
	check_error PACKAGE $? $CAPT_FILE
	#Replace /etc/init.d/ccpd
	echo '#!/bin/bash
# startup script for Canon Printer Daemon for CUPS (ccpd)
### BEGIN INIT INFO
# Provides:          ccpd
# Required-Start:    $local_fs $remote_fs $syslog $network $named
# Should-Start:      $ALL
# Required-Stop:     $syslog $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       Start Canon Printer Daemon for CUPS
### END INIT INFO

# If the CUPS print server is not running, wait until it starts
if [ `ps awx | grep cupsd | grep -v grep | wc -l` -eq 0 ]; then
	while [ `ps awx | grep cupsd | grep -v grep | wc -l` -eq 0 ]
	do
		sleep 3
	done
	sleep 5
fi

ccpd_start ()
{
	echo -n "Đang khởi động ${DAEMON}: "
	start-stop-daemon --start --quiet --oknodo --exec ${DAEMON}
}

ccpd_stop ()
{
	echo -n "Đang dừng ${DAEMON}: "
	start-stop-daemon --stop --quiet --oknodo --retry TERM/30/KILL/5 --exec ${DAEMON}
}

DAEMON=/usr/sbin/ccpd
case $1 in
	start)
		ccpd_start
		;;
	stop)
		ccpd_stop
		;;
	status)
		echo "${DAEMON}:" $(pidof ${DAEMON})
		;;
	restart)
		while true
		do
			ccpd_stop
			ccpd_start
			# if the ccpd process does not appear after 5 seconds, we restart it again
			for (( i = 1 ; i <= 5 ; i++ ))
			do
				sleep 1
				set -- $(pidof ${DAEMON})
				[ -n "$1" -a -n "$2" ] && exit 0
			done
		done
		;;
	*)
		echo "Cách dùng: ccpd {start|stop|status|restart}"
		exit 1
		;;
esac
exit 0' > /etc/init.d/ccpd
	#Installation utilities for managing AppArmor
	apt-get -y install apparmor-utils
	#Set AppArmor security profile for cupsd to complain mode
	aa-complain /usr/sbin/cupsd
	echo 'Đang khởi động lại CUPS'
	service cups restart
	if [ $ARCH == 'amd64' ]; then
		echo 'Đang cài thư viện 32-bit cần thiết để chạy driver máy in 64-bit'
		apt-get -y install libatk1.0-0t64:i386 libcairo2:i386 libgtk2.0-0t64:i386 libpango-1.0-0:i386 libstdc++6:i386 libpopt0:i386 libxml2:i386 libc6:i386
		check_error PACKAGE $?
	fi
	echo 'Đang thêm máy in vào CUPS'
	/usr/sbin/lpadmin -p $NAMEPRINTER -P /usr/share/cups/model/CNCUPSLBP${LASERSHOT[$NAMEPRINTER]}CAPTK.ppd -v ccp://localhost:59687 -E
	echo "Đang đặt $NAMEPRINTER làm máy in mặc định"
	/usr/sbin/lpadmin -d $NAMEPRINTER
	echo 'Đang đăng ký máy in trong cấu hình dịch vụ ccpd'
	/usr/sbin/ccpdadmin -p $NAMEPRINTER -o $PATH_DEVICE
	#Verify printer installation
	installed_printer=$(ccpdadmin | grep $NAMEPRINTER | awk '{print $3}')
	if [ -n "$installed_printer" ]; then
		if [ "$CONECTION" == "usb" ]; then
			echo 'Đang tạo quy tắc nhận diện máy in'
			#A rule is created to provides an alternative name (a symbolic link) to our printer so as not to depend on the changing values of lp0, lp1,...
			echo 'KERNEL=="lp[0-9]*", SUBSYSTEMS=="usb", ATTRS{serial}=='$PRINTER_SERIAL', SYMLINK+="canon'$NAMEPRINTER'"' > /etc/udev/rules.d/85-canon-capt.rules
			#Update the rules
			udevadm control --reload-rules
			#Check the created rule
			until [ -e $PATH_DEVICE ]
			do
				echo -ne "Hãy tắt máy in, chờ 2 giây rồi bật lại máy in\r"
				sleep 2
			done
		fi
		echo -e "\e[2KĐang chạy dịch vụ ccpd"
		service ccpd restart
		#Autoload ccpd
		if [ $INIT_SYSTEM == 'systemd' ]; then
			update-rc.d ccpd defaults
		else
			echo 'description "Canon Printer Daemon for CUPS (ccpd)"
author "LinuxMania <customer@linuxmania.jp>"
start on (started cups and runlevel [2345])
stop on runlevel [016]
expect fork
respawn
exec /usr/sbin/ccpd start' > /etc/init/ccpd-start.conf
		fi
		#Create captstatusui shortcut on desktop
		echo '#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Name='$NAMEPRINTER'
GenericName=Trình theo dõi trạng thái máy in Canon CAPT
Exec=captstatusui -P '$NAMEPRINTER'
Terminal=false
Type=Application
Icon=/usr/share/icons/Humanity/devices/48/printer.svg' > "${XDG_DESKTOP_DIR}/$NAMEPRINTER.desktop"
		chmod 775 "${XDG_DESKTOP_DIR}/$NAMEPRINTER.desktop"
		chown $LOGIN_USER:$LOGIN_USER "${XDG_DESKTOP_DIR}/$NAMEPRINTER.desktop"
		#Install autoshutdowntool for supported models
		if [[ "${!ASDT_SUPPORTED_MODELS[@]}" =~ "$NAMEPRINTER" ]]; then
			SERIALRANGE=(${ASDT_SUPPORTED_MODELS[$NAMEPRINTER]})
			SERIALMIN=${SERIALRANGE[0]}
			SERIALMAX=${SERIALRANGE[1]}
			if [[ ${#PRINTER_SERIAL} -eq ${#SERIALMIN} && $PRINTER_SERIAL > $SERIALMIN && $PRINTER_SERIAL < $SERIALMAX || $PRINTER_SERIAL == $SERIALMIN || $PRINTER_SERIAL == $SERIALMAX ]]; then
				echo "Đang cài tiện ích tự động tắt máy in"
				ASDT_FILE=autoshutdowntool_1.00-1_${ARCH}_deb.tar.gz
				if [ ! -f $ASDT_FILE ]; then
					wget -O $ASDT_FILE ${URL_ASDT[$ARCH]}
					check_error WGET $? $ASDT_FILE
				fi
				tar --gzip --extract --file=$ASDT_FILE --totals --directory=/usr/bin
			fi
		fi
		#Start captstatusui
		if [[ -n "$DISPLAY" ]] ; then
			sudo -u $LOGIN_USER nohup captstatusui -P $NAMEPRINTER > /dev/null 2>&1 &
			sleep 5
		fi
		echo 'Đã cài đặt xong. Nhấn phím bất kỳ để thoát'
		read -s -n1
		exit 0
	else
		echo "Không cài đặt được driver cho máy in $NAMEPRINTER!"
		echo 'Nhấn phím bất kỳ để thoát'
		read -s -n1
		exit 1
	fi
}

function canon_help {
	clear
	echo 'LƯU Ý KHI CÀI ĐẶT
Nếu bạn đã cài driver cho dòng máy in này,
hãy gỡ cài đặt driver cũ trước khi chạy script.
Nếu chưa có sẵn các gói driver, script sẽ tự động
tải chúng từ Internet và lưu vào thư mục chứa script.
Muốn cập nhật driver, trước tiên hãy dùng script này để gỡ bản cũ,
sau đó cài đặt lại bản mới.

XỬ LÝ KHI GẶP SỰ CỐ IN:
Nếu máy in không in, hãy mở trình theo dõi trạng thái bằng lối tắt
trên Màn hình nền hoặc chạy lệnh trong Terminal: captstatusui -P <tên_máy_in>
Cửa sổ captstatusui sẽ hiển thị trạng thái hiện tại của máy in.
Nếu có lỗi, mô tả lỗi sẽ được hiển thị tại đây.
Bạn có thể thử nhấn nút "Resume Job" để tiếp tục in
hoặc nút "Cancel Job" để hủy lệnh in.
Nếu vẫn không được, hãy thử chạy canon_restart.sh

Lệnh mở phần cấu hình máy in: cngplp
Lệnh mở phần thiết lập bổ sung: captstatusui -P <tên_máy_in>
Bật chức năng tự động tắt máy in (không áp dụng cho mọi model): autoshutdowntool
Để ghi lại quá trình cài đặt vào file nhật ký, chạy:
logsave log.txt ./canon_lbp_setup.sh
'
}

clear
echo 'Cài driver máy in Linux CAPT phiên bản '${DRIVER_VERSION}' cho máy in Canon LBP trên Ubuntu (32-bit và 64-bit)
Các máy in được hỗ trợ:'
echo "$NAMESPRINTERS" | sed ':a; /$/N; s/\n/, /; ta' | fold -s

PS3='Hãy nhập lựa chọn của bạn: '
select opt in 'Cài đặt' 'Gỡ cài đặt' 'Trợ giúp' 'Thoát'
do
	if [ "$opt" == 'Cài đặt' ]; then
		canon_install
		break
	elif [ "$opt" == 'Gỡ cài đặt' ]; then
		canon_uninstall
		break
	elif [ "$opt" == 'Trợ giúp' ]; then
		canon_help
	elif [ "$opt" == 'Thoát' ]; then
		break
	fi
done
