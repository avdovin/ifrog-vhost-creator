#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Нужно запуститься под рутом!"
  exit
fi
project_name=$1
echo "Создаем проект под именем $project_name?"
echo "Введи еще раз имя: "
read project_name_prompt
if [[ "$project_name" != "$project_name_prompt" ]]; then
	echo "Не прошли проверку :("
	exit
fi
echo Создаем директорию
mkdir /var/www/$project_name.dev
echo Создаем cgi-bin и httpdocs
mkdir /var/www/$project_name.dev/cgi-bin
mkdir /var/www/$project_name.dev/httpdocs
echo Создаем виртуальный хост Apache
touch /etc/apache2/sites-available/$project_name.dev.conf
echo "<VirtualHost *:8000>" >> /etc/apache2/sites-available/$project_name.dev.conf
echo '	ServerName $project_name.dev' >> /etc/apache2/sites-available/$project_name.dev.conf
echo "	ServerAlias $project_name.dev.ifrog.ru" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "	DocumentRoot /var/www/$project_name.dev/httpdocs" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "	ScriptAlias /cgi-bin/  '/var/www/$project_name.dev/cgi-bin/'" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "	RewriteEngine On" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "	<Directory '/var/www/$project_name.dev/cgi-bin/'>" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "		AddHandler cgi-script .fcgi .cgi .pl" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "		SetHandler cgi-script " >> /etc/apache2/sites-available/$project_name.dev.conf
echo "		AllowOverride None" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "		Order allow,deny" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "		Allow from all" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "	</Directory>" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "	<Directory '/var/www/$project_name.dev/httpdocs/'>" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "		Options FollowSymLinks" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "		AllowOverride All" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "		Order allow,deny" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "		Allow from all" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "	</Directory>" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "	LogLevel info" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "	ErrorLog /var/log/apache2/$project_name.dev-error.log" >> /etc/apache2/sites-available/$project_name.dev.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/$project_name.dev.conf
echo Активируем виртуальный хост
service a2ensite $project_name.dev
echo Создаем зону DNS
touch /etc/bind/zones/db.$project_name.dev
echo '$TTL    604800' >> /etc/bind/zones/db.$project_name.dev
echo "@       IN      SOA     $project_name.dev.ifrog.ru. root.$project_name.dev.ifrog.ru. (" >> /etc/bind/zones/db.$project_name.dev
echo "                     $dns_date         ; Serial (format: yyyymmddhh)" >> /etc/bind/zones/db.$project_name.dev
echo "                         604800         ; Refresh" >> /etc/bind/zones/db.$project_name.dev
echo "                          86400         ; Retry" >> /etc/bind/zones/db.$project_name.dev
echo "                        2419200         ; Expire" >> /etc/bind/zones/db.$project_name.dev
echo "                         604800 )       ; Negative Cache TTL" >> /etc/bind/zones/db.$project_name.dev
echo "        IN      A       192.168.0.3" >> /etc/bind/zones/db.$project_name.dev
echo ";" >> /etc/bind/zones/db.$project_name.dev
echo "@       IN      NS      ns.$project_name.dev.ifrog.ru." >> /etc/bind/zones/db.$project_name.dev
echo "@       IN      A       192.168.0.3" >> /etc/bind/zones/db.$project_name.dev
echo "@       IN      AAAA    ::1" >> /etc/bind/zones/db.$project_name.dev
echo "ns      IN      A       192.168.0.3" >> /etc/bind/zones/db.$project_name.dev
echo Регистрируем зону DNS
echo "zone '$project_name.dev.ifrog.ru' {" >> /etc/bind/named.conf.local 
echo "	type master;" >> /etc/bind/named.conf.local
echo "	file '/etc/bind/zones/db.$project_name.dev';" >> /etc/bind/named.conf.local
echo "}" >> /etc/bind/named.conf.local
echo Перезапускаем Apache
service apache2 restart
echo Перезапускаем Bind DNS Server
service bind9 restart
echo Готово
