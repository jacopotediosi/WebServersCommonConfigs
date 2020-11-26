#!/bin/bash
set -o nounset -o xtrace

# A simple bash script to backup MySQL DBs in a secure way, with backups rotations and with email alerts support (via cronic) if something goes wrong
#
# Created by JacopoMii (https://www.facebook.com/jacopotediosi)
# I'm not responsible for any data loss or for any damage caused by this script
#
# Put this file inside /root/backup/ and chown it as root:root and chmod it to 700 or 770. It runs only as root to mantain backups secure.
# Rapid crontab command (do a backup every day at 2am):
#   MAILTO=admin@example.com
#   0 2 * * 0 cronic /root/backup/backup_files.sh

# Some settings
BACKUP_NAME="Backup-DB-$(date +%Y_%m_%d)"       # This MUST contain a date to prevent subsequent backups from overwriting the previous ones
BACKUP_FINAL_LOCATION="/root/backup/backup_db/" # This MUST be a folder dedicated to backups. Every other file will be automatically deleted by this script!
MAX_BACKUP_NUM=15

DB_CONFIG="/root/backup/backup_db.cnf"          # Absolute (!!!) path of config file containing username and password
DB_DATABASE="INSERT-HERE-YOUR DATABASE-NAMES"   # List of databases to backup separed by spaces

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

# Dump DBs into dump.sql
mysqldump --defaults-file="$DB_CONFIG" --no-tablespaces "$DB_DATABASE" > /tmp/"$BACKUP_NAME".sql

# Create the tar.gz file, with max compression (-9) and preserving file permissions. If mail output is too long, remove -v option.
tar -I 'gzip -9' -vcPf "$BACKUP_NAME".tar.gz /tmp/"$BACKUP_NAME".sql

# Remove dump
rm -rf /tmp/"$BACKUP_NAME".sql
