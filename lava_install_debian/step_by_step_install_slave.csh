#!/bin/csh -f

#Function: Support install lava-server on one machine

#Step 01: Install lava
./slave_install

#Step 02: Update lava-slave
set master_info = `egrep master_name ./00_input_information | awk '{print $NF}'`
cat lava-slave | sed -e s/master_name/$master_info/g > lava_slave
sudo cp lava_slave /etc/lava-dispatcher/lava-slave
rm -rf lava_slave

#Step 03: Restart lava. 
./slave_restart

#Step 04: Config tftp boot
sudo cp tftpd-hpa /etc/default/tftpd-hpa

#Step 05: Config serial
cp ser2net.conf ser2net_new.conf 
foreach dev (`ls devices/*`)
	set dev_name = `echo $dev | awk -F'.jinja2' '{print $1}' | awk -F'/' '{print $NF}'`
	set port_num = `egrep -w telnet $dev | awk '{print $7}' | sed -e s/\'//g`
	echo "${port_num}:telnet:600:/dev/${dev_name}:115200 8DATABITS NONE 1STOPBIT banner" >> ser2net_new.conf
end
sudo cp ser2net_new.conf /etc/ser2net.conf
rm -rf ser2net_new.conf

#Step 06: Config boot dir
set OPWD = `pwd`
cd /var/lib/lava/dispatcher/tmp
sudo grub-mknetdir --net-directory=.
sudo cp $OPWD/grub.cfg /var/lib/lava/dispatcher/tmp/boot/grub/
cd $OPWD

#Step 07: Update worker and IP adress
set user_name = `egrep user_name 00_input_information  | awk '{print $2}'`
set token_info = `egrep token 00_input_information  | awk '{print $2}'`
set master = `egrep master_name 00_input_information  | awk '{print $2}'`

#lavacli identities add --uri http://${master}:80/RPC2 --token $token_info --username $user_name default
#lavacli --uri http://${user_name}@${master}:80/RPC2 device-types list
#lavacli --uri http://${user_name}@${master}:80/RPC2 devices list
#lavacli --uri http://${user_name}@${master}:80/RPC2 workers list

set slave_info = `egrep slave_name ./00_input_information | awk '{print $NF}'`
set dispacher_ip = `egrep DISPACHER_IP ./00_input_information | awk '{print $NF}'`
echo $dispacher_ip

sudo cp setdispatcherip.py /usr/local/bin/setdispatcherip.py 
lavacli identities add --uri http://${master}:80/RPC2 --token $token_info --username $user_name default
foreach worker (`lavacli --uri http://${user_name}:$token_info@${master}:80/RPC2 workers list | egrep $slave_info | awk '{print $NF}'`)
	echo $worker
	echo "Add description"
	lavacli --uri http://${user_name}:${token_info}@${master}:80/RPC2 workers update --description "LAVA dispatcher $worker" $worker
	echo "Add DISPACHER_IP"
	/usr/local/bin/setdispatcherip.py http://${user_name}:$token_info@${master}:80/RPC2 $worker $dispacher_ip
end
#lavacli --uri http://${user_name}:$token_info@${master}:80/RPC2 device-types list

##Step 08: Add worker
#set slave_info = `egrep slave_name ./00_input_information | awk '{print $NF}'`
#if (`sudo lava-server manage workers list | egrep -w " $slave_info " | wc -l` == 0) then
#	echo "Add worker $slave_info ...."
#	lavacli --uri http://${user_name}:$token_info@${master}:80/RPC2 workers add $slave_info
#endif
#
##Step 09: Add device-type
#sudo cp device-types/* /etc/lava-server/dispatcher-config/device-types/
#foreach dev_type (`ls ./device-types/* | awk -F'/' '{print $3}' | sed -e 's/.jinja2//g'`)
#	if (`sudo lava-server manage device-types list | egrep -w " $dev_type " | wc -l` == 0) then
#		echo "Add device-types $dev_type ...."
#		lavacli --uri http://${user_name}:$token_info@${master}:80/RPC2 device-types add $dev_type 
#	endif
#end
#
##Step 10: Add devices
#sudo cp devices/* /etc/lava-server/dispatcher-config/devices/
#foreach dev (`ls ./devices/*`)
#	set dev2 = `echo $dev | awk -F'/' '{print $3}' | sed -e 's/.jinja2//g'`
#	set dev_type = `egrep extends $dev  | egrep -v "^#" | awk '{print $3}' | awk -F ".jinja2" '{print $1}' | awk -F"'" '{print $2}'`
#	if (`sudo lava-server manage devices list | egrep -w " $dev2 " | wc -l` == 0) then
#		echo "Add device $dev2 ..."
#		lavacli --uri http://${user_name}:$token_info@${master}:80/RPC2 devices add --type $dev_type --worker $slave_info $dev2
#	endif
#end

#Step 11: 
sudo service tftpd-hpa start 
sudo echo "LOGFILE=/var/log/lava-dispatcher/lava-slave.log" >> /etc/lava-dispatcher/lava-slave

#if ( -s /etc/ser2net.conf ) then
	sudo service ser2net start || exit 7
#endif

sudo touch /var/run/conmux-registry
if (`sudo lsof -i :63000 | awk '{print $2}' | egrep -v PID` != "") then
	sudo kill `sudo lsof -i :63000 | awk '{print $2}' | egrep -v PID`
endif
sudo /usr/sbin/conmux-registry 63000 /var/run/conmux-registry&
#sleep 2
foreach dev (`ls devices/*`)
	set port_num = `egrep -w telnet $dev | awk '{print $7}' | sed -e s/\'//g`
	#echo $port_num
	if ($port_num != "") then
		sudo kill `sudo lsof -i :$port_num | awk '{print $2}' | egrep -v PID`
		sudo /usr/sbin/conmux-registry $port_num /var/run/conmux-registry&
	endif
end

foreach item (`ls /etc/conmux/*cf`)
	if ($item != "") then
		echo "Add $item"
		# On some OS, the rights/user from host are not duplicated on guest
		grep -o '/dev/[a-zA-Z0-9_-]*' $item | xargs chown uucp
		/usr/sbin/conmux $item &
	endif
end

#HAVE_SCREEN=0
#while read screenboard
#do
#	echo "Start screen for $screenboard"
#	TERM=xterm screen -d -m -S $screenboard /dev/$screenboard 115200 -ixoff -ixon || exit 9
#	HAVE_SCREEN=1
#done < /root/lava-screen.conf
#if [ $HAVE_SCREEN -eq 1 ];then
#	sed -i 's,UsePAM.*yes,UsePAM no,' /etc/ssh/sshd_config || exit 10
#	service ssh start || exit 11
#fi


# start an http file server for boot/transfer_overlay support
(cd /var/lib/lava/dispatcher; python3 -m http.server 80) &

# FIXME lava-slave does not run if old pid is present
rm -f /var/run/lava-slave.pid

#/root/entrypoint.sh
