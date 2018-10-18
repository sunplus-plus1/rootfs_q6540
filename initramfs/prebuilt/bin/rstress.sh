OUT=">&1"

if [ "$1" != "" ];then
	OUT=">$1"
fi

while :
do
	sleep 0.1

	eval memtester 1M 1 $OUT
	if [ $? -ne 0 ];then
		echo "mem test error!!!!"
		exit 1
	fi;

	eval memspeed_test 5 5 1 $OUT
	eval ramspeed -b 1 $OUT
	eval ramspeed -b 2 $OUT
	eval ramspeed -b 3 $OUT
done
