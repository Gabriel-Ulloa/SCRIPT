#!/bin/bash
#
COWRIE_JSON="cowrie.json"
FILE_DOWNLOAD=".file_download"
FILE_UPLOAD=".file_upload"
SESSIONS="sessions.txt"
SESSION_REGEX="[ssion]\+.[:]\+.[0-z]\+"
TIME_REGEX="[a-z]\+.[:]\+.[0-9]\+.[-]\+.[0-9]\+.[0-Z]\+.[0-Z]\+"
IP_REGEX="[:-z]\+.[:]\+.[0-9]\+.[.]\+.[0-9]\+.[0-9]\+.[0-9]\+"
HIP_REGEX="[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+"
SHA_REGEX="[shasum]\+.[:]\+.[0-z]\+"
TIME_0="time_0.tmp"
TIME_N="time_n.tmp"
IPS_FOUND="IPs"
DIR_CHECK="/home/tsec/CHECKS/check_"$(date +"%Y-%m-%d_%H-%M")/""
COWRIE_JSON="/data/cowrie/log/cowrie.json"
PCAP="/home/tsec/PCAP/tcpdump.pcap"
SAMPLE="sample_"$(date +"%Y-%m-%d_%H-%M")".pcap"
temp_1=$(mktemp)
#
mkdir $DIR_CHECK && cp $COWRIE_JSON $DIR_CHECK
cp $PCAP $DIR_CHECK
cd $DIR_CHECK
#
cat $COWRIE_JSON |grep -i $FILE_DOWNLOAD |grep -oe $IP_REGEX |grep -oe $HIP_REGEX | sort | uniq >$temp_1
cat $COWRIE_JSON |grep -i $FILE_UPLOAD |grep -oe $IP_REGEX |grep -oe $HIP_REGEX | sort | uniq >>$temp_1
sed '/^$/d' $temp_1 > $IPS_FOUND
#
while true 
do
    for file in $IPS_FOUND; do
        if [ ! -s "$file" ]; then
            echo "El archivo $file está vacío. Saliendo del bucle..."
            rm $IPS_FOUND
            exit
        fi
        echo "$IPS_FOUND Encontradas"
        mkdir $(sed '2,$d' $IPS_FOUND)
        cp $COWRIE_JSON ./$(sed '2,$d' $IPS_FOUND)
        cp $IPS_FOUND ./$(sed '2,$d' $IPS_FOUND)
        cd $(sed '2,$d' $IPS_FOUND)
        cat $COWRIE_JSON |grep -i $(sed '2,$d' $IPS_FOUND) |sed '2,$d' |grep -oe $TIME_REGEX |cut -c 13-34 |sed 's/T/ /g' >$TIME_0 && sed -i 's/$/:00/' $TIME_0
        cat $COWRIE_JSON |grep -i $(sed '2,$d' $IPS_FOUND) |sed -n '$p' |grep -oe $TIME_REGEX |cut -c 13-34 |sed 's/T/ /g' >$TIME_N && sed -i 's/$/:59/' $TIME_N
        editcap -A "$(cat $TIME_0)" -B "$(cat $TIME_N)" $PCAP $SAMPLE
        awk 'NR>1{print}' $IPS_FOUND >../$IPS_FOUND
        cd ..
    done
done 