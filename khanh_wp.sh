#!/bin/bash	
function download()
	{
	echo "Tao thu muc chua bo cai sample"
        #mkdir /tmp/www/
	cd /var/www/
	echo "Tai bo cai dat Wordpress"
	wget http://wordpress.org/latest.tar.gz
	echo "Thuc hien giai nen"
	tar -xzf latest.tar.gz
	echo "Giai nen thanh cong ^^"
}
function makevhost()
	{
	filename="/root/domain.txt"
	while read line
	do 
	   domain=$line
	   echo "Tao thu muc theo domain"
	   cp -r /var/www/wordpress /var/www/$domain
	   echo "Tao vhost thanh cong" $domain
	done < $filename

}
function edit()
	{
	filename="/root/domain.txt"
	while read line
	do
	   domain=$line
           userpass="admin123"
	   echo "Tao file cau hinh Wordpress ..."
	   cd /var/www/$domain
	   cp wp-config-sample.php wp-config.php
	   sed -i "s/database_name_here/$domain/;s/username_here/$domain/;s/password_here/$userpass/" wp-config.php
	   mkdir wp-content/uploads
	   chmod 640 wp-config.php
	   chmod 775 wp-content/uploads
	   chown www-data: -R /var/www/$domain
	   echo "Chinh sua xong file cua domain " $domain
	   echo "Ket thuc chinh sua"
	done < $filename
}
function createdb()
	{
	filename="/root/domain.txt"
	while read line
	do
 	  tendb=$line
	  passdb="admin123"
	  rootpass="admin123"
	  echo "CREATE DATABASE $tendb;" | mysql -u root -p$rootpass
	  echo "CREATE USER '$tendb'@'localhost' IDENTIFIED BY '$passdb';" | mysql -u root -p$rootpass
	  echo "GRANT ALL PRIVILEGES ON $tendb.* TO '$tendb'@'localhost';" | mysql -u root -p$rootpass
	  echo "FLUSH PRIVILEGES;" | mysql -u root -p$rootpass
	done < $filename
} 
function config()
	{
	filename="/root/domain.txt"
	while read line
	do
	  domain=$line
	echo "
	  <VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName $domain.tk
        ServerAlias www.$domain.tk
        DocumentRoot /var/www/$domain
	</VirtualHost>
	" > /etc/apache2/sites-enabled/$domain."conf"
	done < $filename
}
function import()
	{
	filename="/root/domain.txt"
        while read line
        do
          domain=$line
        echo "Copy du lieu mau.."
	cp /root/sample.sql /var/www/$domain
        echo "Chuyen den thu muc chua sql sample"
	cd /var/www/$domain
	echo "Thu hien chinh sua"
	sed -i "s/epinessne/$domain/;s/epinessne/$domain/;s/epinessne/$domain/" sample.sql
	echo "Thuc hien import du lieu" $domain
	mysql -u root -padmin123 $domain < sample.sql
	echo "Ket thuc ..."
        done < $filename

}
echo "Bat dau chay chuong trinh"
echo "------------------------------------------"
#download
#makevhost
#edit
#createdb
#config
import
echo "Khoi dong lai chuong trinh cai nao"
service apache2 restart
