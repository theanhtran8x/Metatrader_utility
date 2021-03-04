#!/bin/csh -f

#Function: Support install lava-server on one machine

#Step 01: Install lava
./master_install

#Step 02: Update settings.conf
set master_info = `egrep master_name ./00_input_information | awk '{print $NF}'`
cat settings.conf | sed -e s/master_name/$master_info/g > settings_conf
sudo mv settings_conf /etc/lava-server/settings.conf

#Step 03: Restart lava. 
./master_restart

#Step 04: Create admin user
set user_name = `egrep user_name 00_input_information  | awk '{print $2}'`
#set password = `egrep pass_of_admin 00_input_information  | awk '{print $2}'`
#echo "Creating: user = $user_name . And Pasword = Pass1234"
echo "Password of user $user_name"
#sudo lava-server manage createsuperuser --username $user_name --passwd $password --email=anh.tran.jc@renesas.com
sudo lava-server manage createsuperuser --username $user_name --email=anh.tran.jc@renesas.com
#lava-server manage users add --passwd $PASSWORD $USER_OPTION $USER
#lava-server manage tokens add --user $USER --secret $TOKEN


#Step 05: Copy health_check
git clone https://github.com/BayLibre/lava-healthchecks.git
sudo cp lava-healthchecks/health-checks/* /etc/lava-server/dispatcher-config/health-checks/
rm -rf lava-healthchecks
sudo cp health-checks/* /etc/lava-server/dispatcher-config/health-checks/


#Step 06: Add worker
set slave_info = `egrep slave_name ./00_input_information | awk '{print $NF}'`
if (`sudo lava-server manage workers list | egrep -w " $slave_info " | wc -l` == 0) then
	echo "Add worker $slave_info ...."
	sudo lava-server manage workers add $slave_info
endif

#Step 07: Add device-type
sudo cp device-types/* /etc/lava-server/dispatcher-config/device-types/
foreach dev_type (`ls ./device-types/* | awk -F'/' '{print $3}' | sed -e 's/.jinja2//g'`)
	if (`sudo lava-server manage device-types list | egrep -w " $dev_type " | wc -l` == 0) then
		echo "Add device-types $dev_type ...."
		sudo lava-server manage device-types add $dev_type
	endif
end

#Step 08: Add devices
sudo cp devices/* /etc/lava-server/dispatcher-config/devices/
foreach dev (`ls ./devices/*`)
	set dev2 = `echo $dev | awk -F'/' '{print $3}' | sed -e 's/.jinja2//g'`
	set dev_type = `egrep extends $dev  | egrep -v "^#" | awk '{print $3}' | awk -F ".jinja2" '{print $1}' | awk -F"'" '{print $2}'`
	if (`sudo lava-server manage devices list | egrep -w " $dev2 " | wc -l` == 0) then
		echo "Add device $dev2 ..."
		sudo lava-server manage devices add --device-type $dev_type --worker $slave_info $dev2
	endif
end

#Step 09: Change owner 
sudo chown -R lavaserver:lavaserver /var/lib/lava-server/default/media/job-output/
sudo chown -R lavaserver:lavaserver /etc/lava-server/dispatcher-config/devices
sudo chown lavaserver:lavaserver /etc/lava-server/dispatcher-config/device-types/*

