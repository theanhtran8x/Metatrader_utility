# Metatrader_utility
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
