#!/bin/bash




##Autor: vijay  Rajah
##me@rvijay.in



env() {

#declare  -a CMDS

CMDS='uptime
uname -a
date
w
ps aux
df -h
ifconfig -a
iptables -L --line-numbers -v -n
iptables -L --line-numbers -v -n -t nat
pstree -pau
ntpdate -q -u pool.ntp.org
cat /proc/user_beancounters
lsof'

DT=`date +%Y-%m-%d_%Hh%Mm%Ss`
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"

OUT_DIR=/apps/apps-backup
OUT_FILE=${OUT_DIR}/STAT-${DT}.out

IFS='
'

}

do_stats() {

for CMD in $CMDS
do
	echo "############################################ ${CMD} ############################################" >> ${OUT_FILE}
	eval ${CMD} >> ${OUT_FILE} 2>&1
	echo "################################################################################################

" >> ${OUT_FILE}
done
}

env
do_stats
