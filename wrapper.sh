#!/bin/sh

FILETEMP="/flywheel/v0/output/temp.txt"

func_reg()
{
python3 main.py
echo "temp" >> $FILETEMP
sleep 3
}

func_t2map()
{
/usr/local/bin/run_fitT2Map.sh /opt/mcr/v911 /flywheel/v0/config.json
}



## Main script

echo "===REGISTRATION==="
func_reg

while [ ! -f $FILETEMP ]; do sleep 1; done

echo "===T2 MAPPING==="
func_t2map

rm -rf $FILETEMP