#!/bin/bash

#A simple bash script to backup files and folders, in a secure way, with backups rotations and with email alerts if something goes wrong
#Created by JacopoMii (https://www.facebook.com/jacopotediosi)
#I'm not responsible for any data lost or for any damage caused by this script
#TIP: Put this file inside /root and chown it as root:root and chmod it to 700 or 770. Run only as root to mantain backups secure
#Rapid crontab command (do a backup every saturday at 2am): 0 2 * * 6 /root/backup.sh >/dev/null 2>&1

#Some settings
BACKUP_NAME="Backup-Files-$(date +%Y_%m_%d)"   #This MUST contain a date to prevent subsequent backups from overwriting the previous ones
BACKUP_FINAL_LOCATION="/root/backup_files/"    #This MUST be a folder dedicated to backups. Every other file will be automatically deleted by this script!
MAX_BACKUP_NUM=5
FILE_LOCATIONS=(
    "/etc/letsencrypt/live/"
    "/etc/opendkim/keys/"
    "/etc/fail2ban/jail.local"
    "/etc/fail2ban/filter.d/customlogin.conf"
    "/etc/nginx/nginx.conf"
    "/etc/nginx/sites-available/"
    "/etc/ssh/sshd_config"
    "/etc/vsftpd.conf"
    "/etc/vsftpd_user_conf/"
    "/var/www/"
    "/etc/update-motd.d/"
    "/home/"
    "/root/backup_files.sh"
    "/root/backup_db.sh"
    "/root/backup_db.cnf"
)

MAIL_FROM="noreply@example.com"
MAIL_TO="mail1@gmail.com,mail2@gmail.com"      #If multiple mail address please separe with a comma
MAIL_SUBJECT="Error during files backup"

#======================================================================================================
# Do not edit after this point please
#======================================================================================================

#------------------------------------------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------------------------------------------

#Input: integer ErrorCode, integer Critical, string Message
#If ErrorCode is different than 0, it prints Message on console, sends a mail containing the Message and then exit only if Critical is different than 0
function CheckError {
    if [ "$1" -ne 0 ]; then
        echo -e "$3"
        SendMail "$3"
        if [ "$2" -ne 0 ]; then
            exit
        fi
    fi
}

#Input: string Message
#Sends a mail containing the Message and the current datetime
function SendMail {
    echo -e "Subject:${MAIL_SUBJECT}\n$1\nError occurred at $(date +%d/%m/%Y\ %H:%M)" | sendmail -f "${MAIL_FROM}" -t "${MAIL_TO}"
}

#------------------------------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------------------------------

#Check if I am root (this script MUST be root to mantain backups secure)
if [ "$EUID" -ne 0 ]; then
    SendMail "I'm not root"
fi

mkdir -m 700 -p "$BACKUP_FINAL_LOCATION"                                          #Create backup path if not already exists
cd "$BACKUP_FINAL_LOCATION"                                                       #Jumps into
CheckError "$?" "1" "Error jumping into backups folder"                           #Errors handling
mkdir -m 700 -p "$BACKUP_NAME"                                                    #Creating temp folder

#Some flags to detect errors
COPY_ERROR=0
CHMOD_ERROR=0
#Starting backup in temp folder
for i in "${!FILE_LOCATIONS[@]}"; do
    if ! cp --recursive --dereference --parents "${FILE_LOCATIONS[$i]}" ./"$BACKUP_NAME"; then
        COPY_ERROR=1                                                              #Error occurred during cp
    fi
    if ! chmod -R 700 ./"$BACKUP_NAME"; then                                      #Here we chmod to be sure that if backup process crashes, files remain protected
        CHMOD_ERROR=1                                                             #Error occurred during chmod
    fi
done
#Errors handling
CheckError "$COPY_ERROR" "0" "Error copying temporary files"
CheckError "$CHMOD_ERROR" "0" "Error during chmod of temporary files"

zip -qr "$BACKUP_NAME".zip "$BACKUP_NAME"                                         #Zipping (during debug remove "q" parameter)
CheckError "$?" "0" "Error while zipping temporary files"                         #Errors handling

rm -r "$BACKUP_NAME"                                                              #Deleting temp folder
CheckError "$?" "0" "Error while deleting temp folder"                            #Errors handling

rm -rf "$(ls -1t ./ | tail -n +$((MAX_BACKUP_NUM + 1)))"                          #Deleting older backups
CheckError "$?" "0" "Error while deleting older backups"                          #Errors handling

chmod 700 ./"$BACKUP_NAME".zip                                                    #Securing zip file
CheckError "$?" "0" "Error during chmod of backup zip"                            #Errors handling
