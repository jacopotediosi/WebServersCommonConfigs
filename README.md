
# WHAT IS IT

**WebServersCommonConfigs** is a **simple collection of common linux webserver configurations** ready-to-use and already setted up about security.

Each part contains his istructions about what to edit and how to use.

Tested on **Ubuntu Server 18.04 LTS**.

# WHAT IT CONTAINS:

## OpenSSH (/etc/ssh/sshd_config)
**OpenSSH** is an **SSH Daemon** that allows you to **connect and manage** your server from remote<br>
In this repo **we configure it to**:

 - listen on default port 22 (you can choose to change it to mitigate ssh bruteforcing from automatic scanners (Chinese botnets and so on)
 - disallow root login and allow only specific users to login
 - force protocol 2
 - disconnect client not logged in after 1 minute (to not to waste bandwidth)
 - allow only 5 connected clients at the same time and disconnect them after 3 wrong passwords
 - don't print banner/last login (because we use MOTD, see below)
 - use passwords (suggested at least 20 char) for login (but you can also choose to login with keys)
 - ping connected clients with 5 packets every 60 seconds to detect and disconnect ghosts (setting ClientAliveCountMax to 0 disconnect every users in IDLE for 1 minute).

**Installation**: `sudo apt install openssh-server`

**If you have a firewall like ufw**:

    sudo ufw allow ssh  
	sudo ufw enable

Then edit config files as shown in this repo

**Remember** to do `systemctl enable ssh` and `/etc/init.d/ssh start`<br>
If you are connected via SSH and you want to update settings, you probably have to do a system reboot because SSH cannot restart when someone is connected

## Nginx config (/etc/nginx/ and /var/www/)
We now talk about the **webserver nginx**. We'll configure it together with **PHP** and **MySQL**.

Our configs are **ideal for virtualhosts**; they define some security stuffs like **supports for TLS 1.3 and 1.2 only**, **ssl stapling**, **server headers hiding**, **X-XSS-Protection**, **X-Frame-Options**, **X-Content-Type-Options**, automatic redirect from **HTTP to HTTPS**, etc.  **Gzip** is enabled on all files. **HSTS is not forced** (remember to do yoursefl).

**Installation**:

    sudo apt install nginx mysql-server php-fpm php-mysql
    sudo mysql_secure_installation
    sudo nano /etc/php/7.2/fpm/php.ini and change cgi.fix_pathinfo to 0
   
   **If you have a firewall like ufw**:
   
    sudo ufw allow 'Nginx FULL'
    sudo ufw enable

Check with `nginx -v` that your NGINX version is >= 1.13 (to support TLS 1.3) and with `openssl version` that your OpenSSL is >= 1.1.1.<br>
If it isn't:

    cd /tmp/
    wget https://www.openssl.org/source/openssl-1.1.1a.tar.gz
    tar -zxf openssl-1.1.1a.tar.gz && cd openssl-1.1.1a
    ./config
    sudo make
    sudo make install
    sudo mv /usr/bin/openssl /tmp/
    sudo ln -s /usr/local/bin/openssl /usr/bin/openssl && sudo ldconfig

Check if `openssl version` show the correct version<br>
If it throws an error: 

    export LD_LIBRARY_PATH=/usr/local/lib
    echo  "export LD_LIBRARY_PATH=/usr/local/bin/openssl"  >>  ~/.bashrc

Then apply our configs.

**Remember** to do:

 - `sudo systemctl restart php7.2-fpm`
- `sudo systemctl enable php7.2-fpm`
- `sudo systemctl restart nginx`
- `sudo systemctl enable nginx`
- Test TLS configs with https://dev.ssllabs.com/ssltest/ and compare with https://fearby.com/article/enabling-tls-1-3-ssl-on-a-nginx-website-on-an-ubuntu-16-04-server-that-is-using-cloudflare/

For any **trouble**:

 - https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04
 - https://askubuntu.com/questions/1102803/upgrade-openssl-1-1-0-to-1-1-1-in-ubuntu-18-04

## Vsftpd (/etc/vsftpd.conf, /etc/vsftpd_user_conf/ and /etc/vsftpd.userlist)
**VSFTPD** is an FTP Server Daemon that support **FTPS**<br>
In this repo **we configure it** with the same certificate for example.com hosted by nginx, allowing only certain local users to login (no anonymous users) and we restrict them to local specified folders (for example the folder of example.com files).<br>
We also limit clients connected at the same time to 5

**Installation**: `sudo apt install vsftpd`

**If you have a firewall like ufw**:

    sudo ufw allow 20/tcp
    sudo ufw allow 21/tcp
    sudo ufw allow 990/tcp
    sudo ufw allow 40000:50000/tcp
    sudo ufw enable

Then edit config files as shown in this repo

**Remember** that if you want to use FTPS, you first have to setup a certificate (you can use same TLS certificate you use for your website, for sure)

**Remember** to do `sudo systemctl enable vsftpd` and `sudo /etc/init.d/vsftpd start`

In case of **trouble**:
- https://www.digitalocean.com/community/tutorials/how-to-set-up-vsftpd-for-a-user-s-directory-on-ubuntu-16-04
- https://www.liquidweb.com/kb/configure-vsftpd-ssl/

## Fail2Ban (/etc/fail2ban/)

## MOTD (/etc/update-motd.d/)

## Automated backups script (/root/backup.sh)