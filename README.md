
# WHAT IS IT

**WebServersCommonConfigs** is a **simple collection of common linux webserver configurations** ready-to-use and already setted up about security.

Each part contains his istructions about what to edit and how to use.

Tested on **Ubuntu Server 18.04 LTS**.

# WHAT IT CONTAINS:

### Automated backups script (/root/backup.sh)

### Nginx config (/etc/nginx and /var/www/)
OpenSSL 3.0 e versione NGINX

### Fail2Ban (/etc/fail2ban/)

### OpenSSH (/etc/ssh/sshd_config)
**OpenSSH** is an **SSH Daemon** that allows you to **connect and manage** your server from remote<br>
In this repo **we configure it to**:

 - listen on default port 22 (you can choose to change it to mitigate ssh bruteforcing from automatic scanners (Chinese botnets and so on)
 - disallow root login and allow only specific users to login
 - force protocol 2
 - disconnect client not logged in after 1 minute (to not to waste bandwidth)
 - allow only 5 connected clients at the same time and disconnect them after 3 wrong passwords
 - don't print banner/last login (because we use MOTD, see below)
 - use passwords (suggested at least 20 char) for login (but you can also choose to login with keys)
 - ping connected clients with 5 packets every 60 seconds to detect and disconnect ghosts (settings ClientAliveCountMax to 0 disconnect every users in IDLE for 1 minute).

**Installation**: `sudo apt install openssh-server`

### Vsftpd (/etc/vsftpd.conf, /etc/vsftpd_user_conf/ and /etc/vsftpd.userlist)
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

### MOTD (/etc/update-motd.d/)
