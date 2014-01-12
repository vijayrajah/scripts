#!/bin/bash

#####We will take a backup of mysql database and send it to email with optional encryption
####Author: Vijay Rajah (vijayrajah@gmail.com)


##dependencies
##split command (to split the archive if it is above a certain size)
##mailx to send mail
##openssl for encryption
###ofcourse mysql needs to be installed :-)

env() {

##we will set the environment here

DT=`date +%Y-%m-%d_%Hh%Mm%Ss`
TMP_DIR=/tmp/$$
if [ ! -d ${TMP_DIR} ]; then
	mkdir ${TMP_DIR}
fi

EMAIL_BODY=${TMP_DIR}/EMAIL_BODY
MAIL_RCPT="me@rvijay.me"
MAIL_MAX_SIZE="30000000" ##in bytes 30M
ENC_PASSWD="Password0!@" ##passprase for encryption
ENC_SALT="1f2e3d"
ENC_ALGO="aes-256-cbc"
PHP=/usr/bin/php
WIKI_PATH=/apps/web/apache/2.4.4/htdocs/mediawiki/
BAK_DIR=/tmp
SUBJECT="Backup of mediawiki pages on ${DT}"
BAK_ARCHIVE=${TMP_DIR}/bak-wiki.${DT}.tar
ENC_IN_FILE=${TMP_DIR}/wiki-${DT}-BAK.tar.bz2
ENC_OUT_FILE=${TMP_DIR}/wiki-${DT}-BAK.tar.bz2.enc
SPLIT_FILENAME=bak-wiki_tar_part-
}

cleanup() {

/bin/rm -rf ${TMP_DIR}
}

do_backup() {

##by default we will do dump of all DB using rooot cred

$PHP ${WIKI_PATH}/maintenance/dumpBackup.php --full | bzip2 -z9 >${TMP_DIR}/wiki-bak.xml.bz2
cd ${WIKI_PATH} && tar -cf - . | bzip2 -z9 > ${TMP_DIR}/files.tar.bz2

##We will create a tar of tar files
cd ${TMP_DIR}
tar -cvf $BAK_ARCHIVE wiki-bak.xml.bz2 files.tar.bz2

}

gen_email_body() {

#We generate a different body for different files....
#This body if for un-split files

cat << EOT > ${EMAIL_BODY}
Hi,

Backup of mediawiki on $DT

Thanks
Vijay
EOT

}

gen_email_body1() {

###We generate a different body for different files....
#This body is for split'ed files...

NO_FILES=$1
MD5_SUM=$2  ###The output of md5sum will output the hash and the file name. WHen sent as param, $2 will be the hash & $3 will be the file name that we do not need
MD5_PART=$4

cat << EOT > ${EMAIL_BODY}
Hi,

This is a splitted & Encrypted  backup of mediawiki installation...

There are ${NO_FILES} files in this splitted archive

Concatenate the files in the order (after decryption) to get the original file. 

The original file's MD5 sum is ${MD5_SUM}
The MD5 sum of this part is ${MD5_PART}

EOT

}

enc_file() {

#Let's encrypt it......
openssl enc -${ENC_ALGO} -e -S ${ENC_SALT} -k \'${ENC_PASSWD}\'  -in $ENC_IN_FILE -out $ENC_OUT_FILE 

}

send_email() {



#openssl enc -${ENC_ALGO} -e -S ${ENC_SALT} -k \'${ENC_PASSWD}\'  -in $ENC_IN_FILE -out $ENC_OUT_FILE 

#mutt -a $ENC_OUT_FILE  -s "$SUBJECT" -x -- ${MAIL_RCPT} < ${EMAIL_BODY}
mailx -a $ENC_OUT_FILE  -s "$SUBJECT" ${MAIL_RCPT} < ${EMAIL_BODY}

}

split_file() {

##We will split files if they are greater than a specified size and send multiple emails
## We expect 1 tar;ed archive to process.. we do no want to process multiple files

SZ=`stat -c "%s" $BAK_ARCHIVE`

if [ $SZ -lt $MAIL_MAX_SIZE ]; then
	##the file size is less than max size we will just send the email...
	ENC_IN_FILE = $BAK_ARCHIVE
	gen_email_body
	send_email
	return 0
else
	##THe file size is more than mx mail size	
	##We will split the archive
	#We will create a dir to send the splitt'ed output files
	SPLIT_DIR=${TMP_DIR}/split
	if [ ! -d ${SPLIT_DIR} ]; then
		mkdir ${SPLIT_DIR}
	fi

	##CD into the split dir so that we create output files in that dir
	cd ${SPLIT_DIR}

	##NOw we split the archive 
	split -d -b $MAIL_MAX_SIZE ${BAK_ARCHIVE} ${SPLIT_FILENAME}

	NO_OF_PARTS=$(((SZ/MAIL_MAX_SIZE)+1))
	MD5=`md5sum ${BAK_ARCHIVE}`

	PART=1
	for file in `ls ${SPLIT_DIR}`
	do
		##We will send oneby one all the parts
		ENC_IN_FILE=${SPLIT_DIR}/$file
		ENC_OUT_FILE=${ENC_IN_FILE}.enc
		
		
		SUBJECT="Backup of Mediawiki -- Part ${PART} / ${NO_OF_PARTS} on ${DT}"
		enc_file
		MD5_PART=`md5sum ${ENC_IN_FILE}`
		gen_email_body1  ${NO_OF_PARTS} ${MD5} ${MD5_PART}
		send_email
		PART=$((PART+1))
	done
fi

}


get_root_cred() {


echo -n Password: 
read -s password
echo


}


##mail
env
do_backup
split_file
#send_email
cleanup

