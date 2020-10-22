# Metatrader_utility
setenv autoload no
setenv initrd_high 0xffffffff
setenv fdt_high 0xffffffff
dhcp
setenv serverip 192.168.5.40
tftp 0x48080000 2/tftp-deploy-37vn4v82/kernel/Image
setenv initrd_size ${filesize}
tftp 0x48000000 3/tftp-deploy-spmkn_6l/dtb/Image-r8a774a1-hihope-rzg2m-ex-idk-1110wr.dtb
setenv bootargs 'console=ttySC0,115200n8 root=/dev/nfs rw nfsroot=192.168.5.40:/var/lib/lava/dispatcher/tmp/3/extract-nfsrootfs-0tjjo1bs,tcp,hard,intr ip=dhcp'
booti 0x48080000 - 0x48000000

sudo apt-get install isc-dhcp-server
sudo sed -i 's,INTERFACESv4="",INTE RFA CES v4="enx0",' /etc/default/isc -dhcp-server
Add the following to /etc/dhcp/dhcpd.conf
subnet 192.168.66.0 netmask 255.255.255.0 {
range 192.168.66.11 192.168.66.250;
option routers 192.168.66.1;
}

{% set static_ip = '192.168.25.43' %}
{% set static_gateway = '192.168.25.1' %}
{% set static_dns = '192.168.25.1' %}
{% set static_netmask = '255.255.255.0' %}


curl http://admin:12345678@192.168.5.39/set.cmd?cmd=setpower+p61=1

{% set poweron_command = 'pduclient --daemon 192.168.5.1 --hostname 127.0.0.1 --
port 3 --command on' %}
{% set poweroff_command = 'pduclient --daemon 192.168.5.1 --hostname 127.0.0.1 -
-port 3 --command off' %}
{% set reboot_command = 'pduclient --daemon 192.168.5.1 --hostname 127.0.0.1 --
port 3 --command reboot' %}

sudo apt-get update
sudo apt-get -y install git python3-pip docker.io
sudo pip3 install --user docker-compose pyyaml
sudo systemctl start docker
sudo systemctl enable docker

sudo apt-get install isc-dhcp-server
sudo sed -i 's,INTERFACESv4="",INTE RFA CES v4="enx0",' /etc/default/isc -dhcp-server
Add the following to /etc/dhcp/dhcpd.conf
subnet 192.168.66.0 netmask 255.255.255.0 {
range 192.168.66.11 192.168.66.250;
option routers 192.168.66.1;
}

git clone https://gitlab.com/cip-project/cip-testing/lava-docker

sudo ./lavalab-gen.py

sudo ./deploy.sh

http://localhost:10080/
