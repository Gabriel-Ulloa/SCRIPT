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
IP_FOUNDS="IPs"
DIR_CHECK="/home/tsec/CHECKS/check_"$(date +"%Y-%m-%d_%H-%M")/""
DIR_COWRIE="/data/cowrie/log/cowrie.json"
PCAP="/home/tsec/PCAP/tcpdump.pcap"
SAMPLE="sample_"$(date +"%Y-%m-%d_%H-%M")""
#
mkdir $DIR_CHECK && cp $DIR_COWRIE $DIR_CHECK
cp $PCAP $DIR_CHECK
cd $DIR_CHECK
#
cat $COWRIE_JSON |grep -i $FILE_DOWNLOAD |grep -oe $IP_REGEX |grep -oe $HIP_REGEX | sort | uniq >IPs.tmp
cat $COWRIE_JSON |grep -i $FILE_UPLOAD |grep -oe $IP_REGEX |grep -oe $HIP_REGEX | sort | uniq >>IPs.tmp
sed '/^$/d' IPs.tmp >IPs &&rm IPs.tmp
#
while true 
do
    for file in IPs; do
        if [ ! -s "$file" ]; then
            echo "El archivo $file está vacío. Saliendo del bucle..."
            rm IPs
            exit
        fi
        echo "IPS Encontradas"
        mkdir $(sed '2,$d' IPs)
        cp $COWRIE_JSON ./$(sed '2,$d' IPs)
        cp IPs ./$(sed '2,$d' IPs)
        cd $(sed '2,$d' IPs)
        cat $COWRIE_JSON |grep -i $(sed '2,$d' IPs) |sed '2,$d' |grep -oe $TIME_REGEX |cut -c 13-34 |sed 's/T/ /g' >$TIME_0
        cat $COWRIE_JSON |grep -i $(sed '2,$d' IPs) |sed -n '$p' |grep -oe $TIME_REGEX |cut -c 13-34 |sed 's/T/ /g' >$TIME_N
        editcap -A $(cat $TIME_0) -B $(cat $TIME_N) $PCAP $SAMPLE
        #cp $TIME_0 $TIME_N ../
        awk 'NR>1{print}' IPs >../IPs
        cd ..
    done
done