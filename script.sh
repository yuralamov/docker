#! /bin/bash

sudo su
apt install -y preload ssh ufw fail2ban install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y

# смена имени
hostnamectl set-hostname docker
sed -i 's/preserve_hostname: false/preserve_hostname: true/' /etc/cloud/cloud.cfg
echo 'docker' > /etc/hosts

# Настройка памяти
swapfl=`swapon --show --noheadings | awk '{print $1}'`
swapoff $swapfl
fallocate -l 8G $swapfl
chmod 600 $swapfl
mkswap $swapfl
swapon $swapfl

# Настройка сети
{
echo 'network:'
echo '  ethernets:'
echo '    eth0:'
echo '      dhcp4: false'
echo '      addresses:'
echo '      - 192.168.0.20/24'
echo '      gateway4: 192.168.0.1'
echo '      nameservers:'
echo '        addresses:'
echo '        - 192.168.0.1'
echo '        - 8.8.8.8'
echo '        search:'
echo '        - WORKGROUP'
echo '  version: 2'
} > /etc/netplan/netplan.yaml
netplan generate
netplan --debug apply

# Настройка брандмауэра
ufw allow OpenSSH
ufw logging medium
ufw allow 1433
ufw allow 9000
ufw enable
ufw reload
ufw status verbose

# Установка docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io -y

# Установка Porteiner
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce

# Установка MS SQL Server 2017
docker pull mcr.microsoft.com/mssql/server:2017-latest
docker volume create sql2017
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Flvby@123" -p 1433:1433 -v sql2017:/var/opt/mssql --name sql2017 -h sql2017 -d mcr.microsoft.com/mssql/server:2017-latest
docker exec -it sql2017 mkdir /var/opt/mssql/backup
docker exec -it sql2017 /opt/mssql/bin/mssql-conf set sqlagent.enabled true
docker restart sql2017

exit
sudo usermod -aG docker $(whoami)
exit
