#!/bin/sh

# tinymembench
tinymembench

# dhrystone
dry2   2> /dev/null
dry2nr 2> /dev/null
dry2o  2> /dev/null

# ramspeed
ramsmp -p 1 -b 1
ramsmp -p 4 -b 1
ramsmp -p 1 -b 2
ramsmp -p 4 -b 2
ramsmp -p 1 -b 3 -l 5
ramsmp -p 4 -b 3 -l 5
ramsmp -p 1 -b 4
ramsmp -p 4 -b 4
ramsmp -p 1 -b 5
ramsmp -p 4 -b 5
ramsmp -p 1 -b 6 -l 5
ramsmp -p 4 -b 6 -l 5
