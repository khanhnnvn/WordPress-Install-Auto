#!/bin/bash
#
# Install WordPress on a Ubuntu 13+ VPS
#

# run as root 
if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# set colors
green=`tput setaf 2`
red=`tput setaf 1`
normal=`tput sgr0`
bold=`tput bold`

# start
echo "${normal}${bold}UBUNTU SITE INSTALLER${normal}"
read -p "Installer adds site files to /var/www, are you ready (y/n)? "
[ "$(echo $REPLY | tr [:upper:] [:lower:])" == "y" ] || exit

# Install WP
read -p "Install WordPress (y/n)? " wpFiles

if [ $wpFiles == "y" ]; then
	read -p "Database name: " dbname
	read -p "Database username: " dbuser

	# If you are going to use root ask about it	
	if [ $dbuser == 'root' ]; then
		read -p "${red}root is not recommended. Use it (y/n)?${normal} " useroot

		if [ $useroot == 'n' ]; then
			read -p "Database username: " dbuser
		fi
	else
		useroot='n'
	fi

	read -s -p "Enter a password for user $dbuser: " userpass
	echo " "

	# Create MySQL database
	read -p "Add MySQL DB user and tables (y/n)? " dbadd
	if [ $dbadd == "y" ]; then
		read -s -p "Enter your MySQL root password: " rootpass
		echo " "

		if [ ! -d /var/lib/mysql/$dbname ]; then
			echo "CREATE DATABASE $dbname;" | mysql -u root -p$rootpass

			if [ -d /var/lib/mysql/$dbname ]; then
				echo "${green}New MySQL database ($dbname) was successfully created${normal}"
			else
				echo "${red}New MySQL database ($dbname) faild to be created${normal}"
			fi

		else
			echo "${red}Your MySQL database ($dbname) already exists${normal}"
		fi

		# if [ $useroot == 'y' ]; then
		# 	echo "${red}You're using root as DB user. ${normal}"
		# else
		# 	# TODO: check if user exists
		# 	echo "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$userpass';" | mysql -u root -p$rootpass
		# 	echo "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';" | mysql -u root -p$rootpass
		# 	echo "FLUSH PRIVILEGES;" | mysql -u root -p$rootpass
		# 	echo "${green}New MySQL user ($dbuser) was successfully created${normal}"
		# fi

		# fork of https://drupal.org/node/1681250
		echo "Checking whether the $dbuser exists and has privileges"

		user_exists=`mysql -u root -p$rootpass -e "SELECT user FROM mysql.user WHERE user = '$dbuser'" | wc -c`
		if [ $user_exists = 0 ]; then
			echo "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$userpass';" | mysql -u root -p$rootpass
			echo "${green}New MySQL user ($dbuser) was successfully created${normal}"
		else
			echo "${red}This MySQL user ($dbuser) already exists${normal}"
		fi

		user_has_privilage=`mysql -u root -p$rootpass -e "SELECT User FROM mysql.db WHERE db = '$dbname' AND user = '$dbuser'" | wc -c`
		if [ $user_has_privilage = 0 ]; then
			echo "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';" | mysql -u root -p$rootpass
			echo "FLUSH PRIVILEGES;" | mysql -u root -p$rootpass
			echo "${green}Add privilages for user ($dbuser) to DB $dbname${normal}"
		else 
			echo "${red}User ($dbuser) already has privilages to DB $dbname${normal}"
		fi

	fi

	# Download, unpack and configure WordPress
	read -r -p "Enter your URL without www [e.g. example.com]: " wpURL
	if [ ! -d /var/www/$wpURL ]; then
		cd /var/www
		wget http://wordpress.org/latest.tar.gz
		tar -xzf latest.tar.gz --transform s/wordpress/$wpURL/
		rm latest.tar.gz
		if [ -d /var/www/$wpURL ]; then
			echo "${green}WordPress downloaded.${normal}"
			cd /var/www/$wpURL
			cp wp-config-sample.php wp-config.php
			sed -i "s/database_name_here/$dbname/;s/username_here/$dbuser/;s/password_here/$userpass/" wp-config.php

			mkdir wp-content/uploads
			chmod 640 wp-config.php
			chmod 775 wp-content/uploads
			chown www-data: -R /var/www/$wpURL
			if [ -f /var/www/$wpURL/wp-config.php ]; then
				echo "${green}WordPress has been configured."
				echo "${red}Go to wp-config.php and add authentication unique keys and salts.${normal}"
			else
				echo "${red}Created WP files. wp-config.php setup faild, do this manually.${normal}"
			fi
		else
			echo "${red}Failed to create WP files. Install them manually.${normal}"
		fi
	else
		echo "${red}Site folder already exists.${normal}"
	fi

else
	echo "Skipping WordPress install."
fi

# Create Apache virtual host
read -p "Do you want to install Apache vhost (y/n)? " apacheFiles

if [ $apacheFiles == "y" ]; then

	if [ -f /etc/apache2/sites-enabled/$wpURL."conf" ]; then
	    echo "${red}This site already has a vhost file.${normal}"
	else

	echo "
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName $wpURL
        ServerAlias www.$wpURL

        DocumentRoot /var/www/$wpURL

        ErrorLog ${APACHE_LOG_DIR}/error.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
" > /etc/apache2/sites-enabled/$wpURL."conf"

	if [ -f /etc/apache2/sites-enabled/$wpURL."conf" ]; then
		echo "${green}Apache vhost file created${normal}"
	else
		echo "${red}Apache vhost failed to install${normal}"
	fi

fi

# Enable the site
a2ensite $wpURL
service apache2 reload

curlText=`curl --user-agent "fogent" --silent "http://$wpURL/wp-admin/install.php" | grep -o -m 1 "Welcome to the famous five minute WordPress installation process" | wc -c`

# http://www.cyberciti.biz/faq/how-to-find-out-the-ip-address-assigned-to-eth0-and-display-ip-only/
yourip=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

if [ $curlText == '65' ]; then
  echo "${green}Go to http://$wpURL and finish install.${normal}";
else
  echo "${green}Go to http://$yourip/$wpURL and config your DNS after.${normal}";
fi

else
	echo "Skipping Apache site install."
fi

# Output
echo "${green}Finished!${normal}"
