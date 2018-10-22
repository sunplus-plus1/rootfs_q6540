while :
do
	sleep 0.1

	memtester 1M 1 >/dev/null
	if [ $? -ne 0 ];then
		echo "mem test error!!!!"
		exit 1
	fi;

	memspeed_test 5 5 1 >/dev/null
	ramspeed -b 1 >/dev/null
	ramspeed -b 2 >/dev/null
	ramspeed -b 3 >/dev/null
done
