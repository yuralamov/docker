#! /bin/bash

sudo su
apt install -y preload ssh ufw fail2ban apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y

# смена имени
hostnamectl set-hostname docker
sed -i 's/preserve_hostname: false/preserve_hostname: true/' /etc/cloud/cloud.cfg
echo 'docker' > /etc/hosts

# Настройка памяти
swapfl=`swapon --show --noheadings | awk '{print $1}'`
swapoff $swapfl
fallocate -l 4G $swapfl
chmod 600 $swapfl
mkswap $swapfl
swapon $swapfl

# Настройка брандмауэра
ufw allow OpenSSH && ufw logging medium
ufw enable && ufw reload && ufw status verbose

# Установка docker
mkdir -p /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update && apt upgrade -y
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Установка Porteiner
docker volume create portainer_data && docker pull portainer/portainer-ce:latest
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

# Установка MS SQL Server 2017
docker pull mcr.microsoft.com/mssql/server:2017-latest
docker volume create sql2017
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Flvby@123" -p 1433:1433 -v sql2017:/var/opt/mssql --name sql2017 -h sql2017 -d mcr.microsoft.com/mssql/server:2017-latest
docker exec -it sql2017 mkdir /var/opt/mssql/backup
docker exec -it sql2017 /opt/mssql/bin/mssql-conf set sqlagent.enabled true
docker restart sql2017

exit
sudo usermod -aG docker $(whoami)
sudo reboot
