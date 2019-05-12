#Change here with your real domain settings and with your php-fpm path.
#This file needs to be chowned by root:root and chmodded to 644.
#Sites-available folder should be chowned by root:root and chmodded to 755.

# example.com server configuration
server {
	listen 80;
	listen [::]:80;
	server_name example.com www.example.com;	#REMEMBER TO CHANGE HERE WITH REAL DOMAIN
	return 301 https://$server_name$request_uri;
}

server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	root /var/www/html/example.com;

	index index.php index.html index.htm;

	server_name example.com www.example.com;	#REMEMBER TO CHANGE HERE WITH REAL DOMAIN

	location / {
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404
		try_files $uri $uri/ /index.php?$query_string;
	}
	
	# Managed by Certbot
	ssl_certificate /etc/letsencrypt/live/PUT-HERE-YOUR-DOMAIN/fullchain.pem;		#CHANGE HERE
	ssl_certificate_key /etc/letsencrypt/live/PUT-HERE-YOUR-DOMAIN/privkey.pem;	#CHANGE HERE
	#include /etc/letsencrypt/options-ssl-nginx.conf;
	ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
	add_header Strict-Transport-Security "max-age=31536000;" always;
	
	# Security headers
	add_header X-XSS-Protection "1; mode=block";
	add_header X-Frame-Options "DENY";
	add_header X-Content-Type-Options nosniff;

	location ~ \.php$ {
                try_files $uri =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_nam$
                fastcgi_param SCRIPT_NAME $fastcgi_script_name;
                fastcgi_index index.php;
                include fastcgi_params;
        }

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	location ~ /\.(?!well-known).* {
		deny all;
	}
	location ~ /\.ht {
		deny all;
	}
}
