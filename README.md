# WHAT IS IT

**WebServersCommonConfigs** is a **simple collection of common linux webserver configurations** ready-to-use and already setted up about security.

Each part contains his istructions about what to edit and how to use.

Tested on **Ubuntu Server 18.04 LTS**.

# WHAT IT CONTAINS:

## OpenSSH (/etc/ssh/sshd_config)
**OpenSSH** is an **SSH Daemon** that allows you to **connect and manage** your server from remote<br>
In this repo **we configure it to**:

 - listen on default port 22 (you can choose to change it to mitigate ssh bruteforcing from automatic scanners (Chinese botnets and so on) on 0.0.0.0 both ipv4 and ipv6
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

If you want, instead of following our tips, you can **generate your own configs** with this powerful tool: https://nginxconfig.io/

Our configs are **ideal for different virtualhosts on same machine**;
they define some security stuffs like **supports for TLS 1.3 and 1.2 only**, **SSL stapling**, **server headers/banners hiding**, **X-XSS-Protection**, **X-Frame-Options**, **X-Content-Type-Options**, automatic redirect from **HTTP to HTTPS**, **HSTS**, etc.
When someone tries to connect to your webserver requesting an **hostname different from those configured** (for example your reverse dns), he'll be redirected to a simple PHP page that olny prints "**Hello World**".
**403** "Forbidden" pages **redirect to 404** "Not found" and **direct access to 404.html returns a 404 error anyway**.
**Gzip** is enabled on all files. 

**Installation**:

    sudo apt install nginx mysql-server php-fpm php-mysql
    sudo mysql_secure_installation
    sudo nano /etc/php/7.2/fpm/php.ini and change cgi.fix_pathinfo to 0
   
   **If you have a firewall like ufw**:
   
    sudo ufw allow 'Nginx FULL'
    sudo ufw enable

**Check with** `nginx -v` that your NGINX version is >= 1.13 (to support TLS 1.3) and with `openssl version` that your OpenSSL is >= 1.1.1.<br>
If it isn't:

    cd /tmp/
    wget https://www.openssl.org/source/openssl-1.1.1a.tar.gz
    tar -zxf openssl-1.1.1a.tar.gz && cd openssl-1.1.1a
    ./config
    sudo make
    sudo make install
    sudo mv /usr/bin/openssl /tmp/
    sudo ln -s /usr/local/bin/openssl /usr/bin/openssl && sudo ldconfig

Now check if `openssl version` show the correct version<br>
**If it throws an error**: 

    export LD_LIBRARY_PATH=/usr/local/lib
    echo  "export LD_LIBRARY_PATH=/usr/local/bin/openssl"  >>  ~/.bashrc
And try again

Then **generate certificates**:

    sudo add-apt-repository ppa:certbot/certbot
    sudo apt install python-certbot-nginx
    sudo certbot --nginx -d example.com -d www.example.com
    sudo certbot --nginx -d YOURREVERSEDNS -d www.YOURREVERSEDNS
Certbot should manage automatically renew for your certificates (that are valid for only 90 days).

Then **apply our configs** (remember corrects chown and chmod).

Then **activate virtualhosts configs**:

    sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
    sudo ln -sf /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/

**Remember** that folders inside /var/www/ need to be chowned by www-data:www-data and chmodded to 770

**Remember** to do:

 - `sudo systemctl restart php7.2-fpm`
- `sudo systemctl enable php7.2-fpm`
- `sudo systemctl restart nginx`
- `sudo systemctl enable nginx`
- **Test TLS** configs with https://dev.ssllabs.com/ssltest/ and compare with https://fearby.com/article/enabling-tls-1-3-ssl-on-a-nginx-website-on-an-ubuntu-16-04-server-that-is-using-cloudflare/

For any **trouble**:

 - https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04
 - https://askubuntu.com/questions/1102803/upgrade-openssl-1-1-0-to-1-1-1-in-ubuntu-18-04
 - https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04

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
**Fail2ban** scans log files and bans for a specified amount of time (updating firewall rules) IPs that show malicious signs, for example too many password failures, seeking for exploits, etc.
Out of the box Fail2Ban comes with a lot of **filters** for various services (apache, courier, ssh, etc).

**Here we'll configure it** to **protect** our **SSH** daemon, our **FTP** connection and a **simple login page of our website**.

**To install**: `sudo pip install pyinotify` and  `sudo apt install fail2ban`

After installation, at /etc/fail2ban/jail.conf you can find a file with a lot of configs already ready for most commonly used services. Please don't edit this file, because it's there only for documentation purposes. Create instead a copy named "jail.local" with your real configs.

If you want you can **copy&paste our configs** from this repo.

**Our jail.local is setted as follows**:
 - **Generic rule** (applied to jails which don't overwrite it): ban for 3 hours IPs that fail filters 100 times in 30 minutes
 - **SSH jail**: ban for 15 days IPs that try wrong passwords for 5 times in 6 hours
 - **VSFTPD jail**: ban for 5 days IPs that try wrong passwords for 6 times in 6 hours
 - **Login jail** (custom defined): ban for 6 hours IPs that do more than 50 POST requests to "/login" in 6 hours (needs you put our file customlogin.conf inside /etc/fail2ban/filter.d/ folder)

**Remember to do**: `sudo /etc/init.d/fail2ban start` and `sudo systemctl enable fail2ban`

**Rapid commands**:
- To view enabled jails: `sudo fail2ban-client status`
- To view details of a jail: `sudo fail2ban-client status sshd` (please change "sshd" with jail name you want to view)
- To unban a specific IP: `sudo fail2ban-client unban IP` (please change "IP" with ip you want to unban)

**Demo**:
A week after putting a server with public ipv4 online, without an associated domain and with SSH on port 22:

![IPs banned from Fail2Ban after 1 week of uptime](https://raw.githubusercontent.com/jacopotediosi/WebServersCommonConfigs/master/images/image1.png)

They were mainly Chinese IPs, probably part of a giant botnet of pwned devices in the world.
But they were banned from fail2ban, so I guess that's working :D

## MOTD (/etc/update-motd.d/)
MOTD is used to show useful information to user immediately after his SSH login.
Our version shows:

 - **Informations** about installed distro and his kernel version
 - **System workloads** (Processes, RAM, CPU, Memory and swap usage)
 - Currently logged in **SSH users** and what they are doing
 - **Expiration of certificates**
 - **Services status**
 - **Fail2ban statistics**
 - Number of **upgradable packages**

![Screenshot of our MOTD](https://github.com/jacopotediosi/WebServersCommonConfigs/blob/master/images/image2.png?raw=true)

**To install**: `sudo apt install update-motd`

Then move our files to /etc/update-motd.d/<br>
**All files need to be chomodded to 755 and chowned to root:root**

All our scripts **have been tested** with **[Shellcheck](https://www.shellcheck.net/)** to detect any **security/syntax issues**

## Automated backups script (/root/backup_files.sh, /root/backup_db.sh and /root/backup_db.cnf)
This is a simple script I wrote to **backup databases and files**.<br>
It's composed of **three files**: *backup_files.sh*, *backup_db.sh* and *backup_db.cnf*.<br>
It's **highly customizable** with some settings to configure in top of each file.<br>
Please note: it **requires sendmail** to be installed and setted up.
Its features are:

 - Good **compatibility** (it's written in bash)
 - **Zip** every backup
 - Autorun with **crontab**
 - **Backup rotation**
 - **Send mail whenever an error occurs**
 - Databases **credentials aren't visible in process list** (ps aux) since a special file (backup_db.cnf) is used to contain them instead of directly putting them inside dumping commands

## Other useful websites:

### To setup sendmail with all stuffs (DKIM, SPF, DMARC etc):
https://philio.me/setting-up-dkim-with-sendmail-on-ubuntu-14-04/
http://meumobi.github.io/sendmail/2015/09/18/install-configure-dkim-sendmail-debian.html

NB: **DKIM is not compatible with** some sendmail features, like **genericstable**.<br>
Use postfix instead of sendmail if you want to use them.

**To send a mail** (**always remember to use -f parameter to not disclose username of local users**): 

**With bash:**

    echo -e "Subject:${MAIL_SUBJECT}\n$1\nThis is the mail body" | sendmail -f "${MAIL_FROM}" -t "${MAIL_TO}"

**With python2:**

    msg = MIMEText("Simple text")
    msg["From"] = "noreply@example.com"
    msg["To"] = "test@test.com,test2@test.com"
    msg["Subject"] = "Simple subject"
    p = Popen(["/usr/sbin/sendmail", "-t", "-oi", "-f"+msg["From"]], stdin=PIPE)
    p.communicate(msg.as_bytes())

### To check DKIM Keys of your DNS records:
https://dkimcore.org/tools/keycheck.html

### To check if your mail will be sent into spam folder:
https://www.mail-tester.com/ <br>
http://www.appmaildev.com/it/dkim <br>
http://dkimvalidator.com/ <br>
https://toolbox.googleapps.com/apps/checkmx/ (Official Website by Google)

### Excellent Intrusion Detection Systems:
https://www.snort.org/
