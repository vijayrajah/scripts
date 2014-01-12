#!/bin/bash

#This will dump app media wiki pages into a dir -- for backup later
####Author: Vijay Rajah (vijayrajah@gmail.com)



env() {

##we will set the environment here

DT=`date +%Y-%m-%d_%Hh%Mm%Ss`
TMP_DIR=/tmp/$$
if [ ! -d ${TMP_DIR} ]; then
	mkdir ${TMP_DIR}
fi

PHP=/usr/bin/php
WIKI_PATH=/apps/web/apache/2.4.4/htdocs/mediawiki/
BAK_DIR=/apps/apps-backup/
BAK_ARCHIVE=${BAK_DIR}/dail-wiki-backup.tar
MYSQL_DB_NAME=wiki_vijay1
MYSQL_DUMP_OPTIONS="--default-character-set=binary --add-drop-table --lock-tables " ## binary charset from LocalSettings.php
MY_CNF_FILE=/root/12shcaert.cnf #<-- Path to backup my.cnf file
}

cleanup() {

/bin/rm -rf ${TMP_DIR}
}

do_backup() {

mysqldump --defaults-extra-file=${MY_CNF_FILE} ${MYSQL_DUMP_OPTIONS} ${MYSQL_DB_NAME} | bzip2 -z9 >${TMP_DIR}/wiki-db-dump.sql.bz2

${PHP} ${WIKI_PATH}/maintenance/dumpBackup.php --full | bzip2 -z9 >${TMP_DIR}/wiki-bak.xml.bz2
cd ${WIKI_PATH} && tar -cpf - . | bzip2 -z9 > ${TMP_DIR}/files.tar.bz2

##We will create a tar of tar files
cd ${TMP_DIR}
tar -cvf $BAK_ARCHIVE wiki-bak.xml.bz2 files.tar.bz2 wiki-db-dump.sql.bz2

}

env
do_backup
cleanup
