#!/bin/bash

# Exit with usage info if no arguments supplied
if [ $# -eq 0 ]; then
	echo "Usage: ./setup.sh <setup.cfg>"
	exit 1
fi

# Exit if config doesn't exist
if [ ! -f $1 ]; then
	echo "Config file doesn't exist!"
	exit 1
fi

# Load config
echo -ne "Loading config..."
source $1
echo "done"

# Install packages
echo "Installing prerequisites..."
yum install expect httpd mysql mysql-server php php-mysql php-xml $packages

# Configure MySQL
echo "Setting up MySQL..."
chkconfig mysqld on
service mysqld start
./mysql.exp $mysql_pw $mysql_new_pw

# Configure Apache
echo "Setting up Apache..."
chkconfig httpd on
service httpd start

# Create database(s) and user(s)
for ((i=0; i<${#mysql_dbs[@]}; i++)); do
	db=${mysql_dbs[$i]}
	mysql --user=root --password=$mysql_new_pw -e "CREATE DATABASE IF NOT EXISTS $db CHARACTER SET utf8;"
	echo "Created database $db"
done

# Create database users
for ((i=0; i<${#mysql_users[@]}; i=i+3)); do
	dbu=${mysql_users[$i]}
	dbo=${mysql_users[$i+1]}
	dbp=${mysql_users[$i+2]}
	mysql --user=root --password=$mysql_new_pw -e "GRANT ALL ON $dbo TO $dbu@localhost IDENTIFIED BY '$dbp';"
	echo "Created database user $dbu"
done

# Import sql dump(s)
for ((i=0; i<${#mysql_sqls[@]}; i=i+4)); do
	sql=${mysql_sqls[$i]}
	echo -ne "Importing $sql..."
	db=${mysql_sqls[$i+1]}
	dbu=${mysql_sqls[$i+2]}
	dbp=${mysql_sqls[$i+3]}
	mysql --user=$dbu --password=$dbp $db < $sql
	echo "done"
done

# Move or extract file(s) to web root
for ((i=0; i<${#files[@]}; i++)); do
	file=${files[$i]}
	if [[ "$file" == *.tar.gz ]]; then
		echo "Extracting $file to /var/www/html"
		tar -zxvf $file -C /var/www/html/
	else
		echo "Copying $file to /var/www/html/"
		cp -r $file /var/www/html/
	fi
done

# Create group(s)
for ((i=0; i<${#groups[@]}; i++)); do
	group=${groups[$i]}
	groupadd $group
	echo "Added group $group"
done

# Create user(s)
for ((i=0; i<${#users[@]}; i=i+3)); do
	user=${users[$i]}
	pw=${users[$i+1]}
	key=${users[$i+2]}
	
	useradd $user
	./passwd.exp $user $pw
	if [[ ! -z "$key" ]]; then
		echo "Installing public key"
		mkdir /home/$user/.ssh
		cat $key > /home/$user/.ssh/authorized_keys
		chown -R $user:$user /home/$user/.ssh
		chmod 700 /home/$user/.ssh
		chmod 600 /home/$user/.ssh/*
	fi
	echo "Added user $user"
done

# Set permissions
echo -ne "Setting standard permissions..."
chown -R apache:apache /var/www/html/*
find /var/www/html/* -type d -exec chmod 755 {} \;
find /var/www/html/* -type f -exec chmod 644 {} \;
chmod -R g+swX /var/www/html/*
find /var/www/html -name id_rsa -exec chmod 600 {} \;
keys=$(dirname $(find /var/www/html -name id_rsa))
echo $keys
if [ -d $keys ]; then
	chmod 700 $keys
fi
find /var/www/html -wholename "*git/hooks/*" ! -name "*.*" -exec chmod +x {} \;
find /var/www/html -wholename "*digitollsync/hooks/*" ! -name "*.*" -exec chmod +x {} \;
echo "done"

# Run bash commands
echo "Executing custom commands..."
for ((i=0; i<${#cmds[@]}; i++)); do
	echo "${cmds[$i]}"
	echo `${cmds[$i]}`
done

echo "Finished!"
echo "Don't forget to configure virtual hosts, SSL, cron jobs, or special permissions!"
