#!/bin/bash



##Check with pid's are using swap
##AUthor: Vijay Rajah
##Email: me@rvijay.in


for i in `ls -d /proc/[1-9]*`
do
	#echo $i
	PSUM=0
	PSUM=`grep Swap ${i}/smaps 2>/dev/null | awk '{SUM+=$2} END {print SUM}'`
	if [ ! -z $PSUM ]; then

		if (( $PSUM > 0)); then
			PID=`basename $i`
			COMM=`ps -p $PID -o comm --no-headers`
			echo "$PID: $COMM : $PSUM"
		fi
	fi

done
