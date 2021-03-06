#!/bin/bash
set -o nounset -o xtrace

# A simple bash script to backup files&folders (mantaining structures and permissions), in a secure way, with backups rotations and with email alerts support (via cronic) if something goes wrong
#
# Created by JacopoMii (https://www.facebook.com/jacopotediosi)
# I'm not responsible for any data loss or for any damage caused by this script
#
# Put this file inside /root/backup/ and chown it as root:root and chmod it to 700 or 770. It runs only as root to mantain backups secure.
# Rapid crontab command (do a backup every day at 2am):
#   MAILTO=admin@example.com
#   0 2 * * * cronic /root/backup/backup_files.sh

# Some settings
BACKUP_NAME="Backup-Files-$(date +%Y_%m_%d)"        # This MUST contain a date to prevent subsequent backups from overwriting the previous ones
BACKUP_FINAL_LOCATION="/root/backup/backup_files/"  # This MUST be a folder dedicated to backups. Every other file will be automatically deleted by this script!
MAX_BACKUP_NUM=5
FILE_LOCATIONS=(
    "/etc/letsencrypt/"
    "/etc/opendkim/"
    "/etc/fail2ban/"
    "/etc/nginx/"
    "/etc/ssh/sshd_config"
    "/etc/vsftpd.conf"
    "/etc/vsftpd_user_conf/"
    "/var/www/"
    "/etc/update-motd.d/"
    "/home/"
    "/root/backup/backup_files.sh"
    "/root/backup/backup_db.sh"
    "/root/backup/backup_db.cnf"
    "/var/spool/cron/crontabs/"
)

#======================================================================================================
# Do not edit after this line please
#======================================================================================================

# Check if I am root (this script MUST be root to mantain backups secure)
if [ "$EUID" -ne 0 ]; then
    >&2 echo "I'm not root"
    exit 1
fi

# Umask to protect files during elaboration
umask 077

# Create backup path if not already exists and jumps into it
mkdir -m 700 -p "$BACKUP_FINAL_LOCATION"
cd "$BACKUP_FINAL_LOCATION" || exit 1

# Create the tar.gz file, with max compression (-9) and preserving file permissions. If mail output is too long, remove -v option.
tar -I 'gzip -9' --warning=no-file-changed --exclude='*.sock' -vcpPf "$BACKUP_NAME".tar.gz "${FILE_LOCATIONS[@]}"

# Delete older backups
ls -tp | tail -n +$((MAX_BACKUP_NUM + 1)) | xargs -d '\n' -r rm -rf --
