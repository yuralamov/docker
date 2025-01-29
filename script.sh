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
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Flvby@123" -p 1433:1433 -e 'MSSQL_PID=Developer' -v sql2017:/var/opt/mssql --name sql2017 -h sql2017 -d mcr.microsoft.com/mssql/server:2017-latest
docker exec -it sql2017 mkdir /var/opt/mssql/backup
docker exec -it sql2017 /opt/mssql/bin/mssql-conf set sqlagent.enabled true
docker restart sql2017

# Установка Postgresql
docker pull postgres
docker volume create postgres_data
docker run --name postgres -h postgres -p 5432:5432 -e POSTGRES_USER=user -e POSTGRES_PASSWORD=User@123 -e POSTGRES_DB=user -e PGDATA=/var/lib/postgresql/data/pgdata -d -v postgres_data:/var/lib/postgresql/data postgres
docker exec -it postgres psql -U user -W testdb

# Установка MySQL
docker pull mysql/mysql-server:latest
docker volume create mysql_data && docker volume create mysql_conf && docker volume create mysql_logs
docker run --name=mysql --hostname=mysql -p 33306:3306 -v mysql_conf:/etc/mysql/my.cnf.d/ -v mysql_data:/var/lib/mysql/ -v mysql_logs:/var/log/ -d mysql/mysql-server:latest
# Сменить пароль root и создать пользователя с супер правами
## docker logs mysql | grep 'GENERATED ROOT PASSWORD:'
## docker exec -it mysql mysql -uroot -p
## ALTER USER 'root'@'localhost' IDENTIFIED BY 'Flvby@123';
## CREATE USER 'user' IDENTIFIED BY 'User@123';
## GRANT ALL PRIVILEGES ON *.* TO 'user'@'%' WITH GRANT OPTION;
## FLUSH PRIVILEGES;
## exit

sudo usermod -aG docker $(whoami)
sudo reboot
