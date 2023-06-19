#!/bin/bash
#
DIR_CHECK="/home/tsec/CHECKS/check_"$(date +"%Y-%m-%d_%H-%M")/""
PCAP="/home/tsec/PCAP/tcpdump.pcap"
SAMPLES_DIR="samples"
SAMPLE="sample_"$(date +"%Y-%m-%d_%H-%M")".pcap"
SAMPLE_TEMP="temp.pcap"
HONEYS="honeypots"
TIME_0="time_0.txt"
TIME_N="time_n.txt"
IPS_FOUND="IPs.txt"
IPS_TEMP="IPs.tmp"
HASH_TEMP="HASH.tmp"
HASHES="hashes.txt"
#
mkdir $DIR_CHECK && cd $DIR_CHECK && mkdir tcpdump && cp $PCAP tcpdump/ && sleep 10
mkdir $HONEYS && cd $HONEYS
#
#####VIRUSTOTAL-CHECKER################
function virus_total(){
    file="hashes.txt" ####REVISAR ESTA SHIT
    counter=0
    while IFS= read -r hash; do
        echo "consultando..." && /home/tsec/SCRIPT/vt file $hash --format json > virustotal/$(echo $hash)_"$(date +"%Y-%m-%d_%H:%M:%S")".json && sleep .5
        counter=$((counter + 1))
        #Verificar si se han revisado doscientas líneas
        if ((counter % 200 == 0)); then
            echo "Esperando 1 minuto..."
            sleep 60
        fi
    done < "$file"
}
#
#DIONAEA############################################################################################
function dionaea(){
    DIONAEA_JSON="/data/dionaea/log/dionaea.json"
    DIONAEA_SQLITE="/data/dionaea/log/dionaea.sqlite"
    DIONAEA_DIR="dionaea_"$(date +"%Y-%m-%d_%H-%M")/""
    DOWNLOADS="downloads.csv"
    CONNECTIONS="connections.csv"
    #
    mkdir $DIONAEA_DIR && cd $DIONAEA_DIR
    mkdir $SAMPLES_DIR && cd $SAMPLES_DIR
    #####Documentos###
    cp $DIONAEA_JSON $DIONAEA_SQLITE .
    sqlite3 -header -csv dionaea.sqlite "SELECT * FROM downloads" > $DOWNLOADS
    sqlite3 -header -csv dionaea.sqlite "SELECT * FROM connections" > $CONNECTIONS
    cut -d ',' -f 4 downloads.csv |sed '1d' | sort | uniq > $HASHES
    #
    function time_extractor(){
        
        DIONAEA_LOCAL="../../dionaea.json"
        LOCAL_REGEX="[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+"

        cp $IPS_FOUND $IPS_TEMP

        while true 
        do
            for file in $IPS_TEMP; do
                if [ ! -s "$file" ]; then
                    echo "El archivo $file está vacío. Saliendo del bucle..."
                    rm $IPS_TEMP
                    return
                fi
                echo "Direccciones IP encontradas" 
                mkdir $(sed '2,$d' $IPS_TEMP) 
                cp $IPS_TEMP ./$(sed '2,$d' $IPS_TEMP) 
                cd $(sed '2,$d' $IPS_TEMP) 
                grep -i $(sed '2,$d' $IPS_TEMP) $DIONAEA_LOCAL |head -n 1 |grep -oe $LOCAL_REGEX |sed -n '$p' |sed 's/T/ /g' >$TIME_0 && sed -i 's/$/:00/' $TIME_0
                grep -i $(sed '2,$d' $IPS_TEMP) $DIONAEA_LOCAL |tail -n 1 |grep -oe $LOCAL_REGEX |sed -n '$p' |sed 's/T/ /g' >$TIME_N && sed -i 's/$/:59/' $TIME_N
                editcap -A "$(cat $TIME_0)" -B "$(cat $TIME_N)" $PCAP $SAMPLE_TEMP
                #tcpdump -r tcpdump.pcap -w nuevo_archivo.pcap host 167.99.171.68
                tcpdump -r $SAMPLE_TEMP -w $SAMPLE host $(sed '2,$d' $IPS_TEMP)
                awk 'NR>1{print}' $IPS_TEMP > ../$IPS_TEMP 
                head -n 1 $IPS_TEMP > IP.txt && rm $IPS_TEMP && rm $SAMPLE_TEMP
                cd ..
            done
        done
    }
#
    function hash_extractor(){
       
        CONNECTION_LOCAL="connection.txt"

        cp $HASHES $HASH_TEMP

        while true 
        do
            for file in $HASH_TEMP; do
                if [ ! -s "$file" ]; then
                    echo "El archivo $file está vacío. Saliendo del bucle..."
                    rm $HASH_TEMP
                    mkdir virustotal
                    virus_total
                    cd ..
                    mkdir malwares
                    tar -czvf malwares/binaries_"$(date +"%Y-%m-%d")".tar.gz /data/dionaea/binaries/
                    echo "Dionaea DONE" >DONE.txt
                    cd ..
                    return
                fi
                echo "Hashes encontrados" 
                mkdir $(sed '2,$d' $HASH_TEMP) 
                cp $HASH_TEMP ./$(sed '2,$d' $HASH_TEMP)
                cd $(sed '2,$d' $HASH_TEMP)
                grep $(sed '2,$d' $HASH_TEMP) ../$DOWNLOADS |cut -d ',' -f 1 > $CONNECTION_LOCAL && grep "^$(cat $CONNECTION_LOCAL)," "../$CONNECTIONS" |cut -d',' -f10 |sort |uniq > $IPS_FOUND
                awk 'NR>1{print}' $HASH_TEMP >../$HASH_TEMP 
                head -n 1 $HASH_TEMP > hash.txt && rm $HASH_TEMP
                time_extractor
                cd ..
            done
        done
    }

hash_extractor

}

dionaea
###############################################################################################DIONAEA
#
#COWRIE###############################################################################################
function cowrie(){
    
    COWRIE_JSON="/data/cowrie/log/cowrie.json"
    COWRIE_LOCAL="cowrie.json"
    FILE_DOWNLOAD=".file_download"
    SHA_REGEX="[shasum]\+.[:]\+.[0-z]\+"
    IP_REGEX="[:-z]\+.[:]\+.[0-9]\+.[.]\+.[0-9]\+.[0-9]\+.[0-9]\+"
    HIP_REGEX="[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+"
    TIME_REGEX="[a-z]\+.[:]\+.[0-9]\+.[-]\+.[0-9]\+.[0-Z]\+"
    COWRIE_DIR="cowrie_"$(date +"%Y-%m-%d_%H-%M")/""
    
    mkdir $COWRIE_DIR && cd $COWRIE_DIR
    mkdir $SAMPLES_DIR && cd $SAMPLES_DIR
    cp $COWRIE_JSON .
    grep -i $FILE_DOWNLOAD $COWRIE_LOCAL |grep -oe $SHA_REGEX |cut -c 10-74 | sort | uniq > $HASHES
    #
    function time_extractor(){

        cp $IPS_FOUND $IPS_TEMP

        while true 
        do
            for file in $IPS_TEMP; do
                if [ ! -s "$file" ]; then
                    echo "El archivo $file está vacío. Saliendo del bucle..."
                    rm $IPS_TEMP
                    return
                fi
                echo "Direccciones IP encontradas" 
                mkdir $(sed '2,$d' $IPS_TEMP) 
                cp $IPS_TEMP ./$(sed '2,$d' $IPS_TEMP) 
                cd $(sed '2,$d' $IPS_TEMP) 
                grep -i $(sed '2,$d' $IPS_TEMP) ../../$COWRIE_LOCAL |sed '2,$d' |grep -oe $TIME_REGEX |cut -c 13-28 |sed 's/T/ /g' >$TIME_0 && sed -i 's/$/:00/' $TIME_0
                grep -i $(sed '2,$d' $IPS_TEMP) ../../$COWRIE_LOCAL |sed -n '$p' |grep -oe $TIME_REGEX |cut -c 13-28 |sed 's/T/ /g' >$TIME_N && sed -i 's/$/:59/' $TIME_N
                editcap -A "$(cat $TIME_0)" -B "$(cat $TIME_N)" $PCAP $SAMPLE_TEMP
                tcpdump -r $SAMPLE_TEMP -w $SAMPLE host $(sed '2,$d' $IPS_TEMP)
                awk 'NR>1{print}' $IPS_TEMP > ../$IPS_TEMP
                head -n 1 $IPS_TEMP > IP.txt && rm $IPS_TEMP && rm $SAMPLE_TEMP
                cd ..
            done
        done
    }

    function hash_extractor(){

        cp $HASHES $HASH_TEMP

        while true 
        do
            for file in $HASH_TEMP; do
                if [ ! -s "$file" ]; then
                    echo "El archivo $file está vacío. Saliendo del bucle..."
                    rm $HASH_TEMP
                    mkdir virustotal
                    virus_total
                    cd ..
                    mkdir malwares
                    tar -czvf malwares/downloads_"$(date +"%Y-%m-%d")".tar.gz /data/cowrie/downloads/
                    echo "Cowrie DONE" >DONE.txt
                    cd ..
                    return
                fi
                echo "Hashes encontrados" 
                mkdir $(sed '2,$d' $HASH_TEMP) 
                cp $HASH_TEMP ./$(sed '2,$d' $HASH_TEMP)
                cd $(sed '2,$d' $HASH_TEMP)
                grep $(sed '2,$d' $HASH_TEMP) ../$COWRIE_LOCAL |grep -oe $IP_REGEX |grep -oe $HIP_REGEX | sort | uniq > $IPS_FOUND
                awk 'NR>1{print}' $HASH_TEMP >../$HASH_TEMP
                head -n 1 $HASH_TEMP > hash.txt && rm $HASH_TEMP
                time_extractor
                cd ..
            done
        done
    }

hash_extractor

}

cowrie
#############################################################################################COWRIE
#
#ADBhoney#####################################################################################
function ADBhoney(){
    
    ADB_LOG="/data/adbhoney/log/adbhoney.log"
    ADB_LOCAL="adbhoney.log"
    ADB_DIR="ADB_"$(date +"%Y-%m-%d_%H-%M")/""

    mkdir $ADB_DIR && cd $ADB_DIR
    mkdir $SAMPLES_DIR && cd $SAMPLES_DIR
    cp $ADB_LOG .
    grep -i ".session.connect" $ADB_LOCAL |grep -oe "[src_ip]\+.[:_ ]\+.[0-9]\+.[.]\+.[0-9]\+.[0-9]\+.[0-9]\+" |grep -v "172.18.0.2" |cut -d "'" -f 3 | sort | uniq > $IPS_FOUND
    grep -i ".file_download" $ADB_LOCAL |grep -oe "[shasum]\+.[:_ ]\+.[0-z]\+" |cut -c 11-74 | sort | uniq > $HASHES
    cp $IPS_FOUND $IPS_TEMP

    function time_extractor(){

        while true 
        do
            for file in $IPS_TEMP; do
                if [ ! -s "$file" ]; then
                    echo "El archivo $file está vacío. Saliendo del bucle..."
                    rm $IPS_TEMP
                    mkdir virustotal
                    virus_total
                    cd ..
                    mkdir malwares
                    tar -czvf malwares/downloads_"$(date +"%Y-%m-%d")".tar.gz /data/adbhoney/downloads/
                    echo "ADB DONE" >DONE.txt
                    return
                fi
                echo "Direccciones IP encontradas" 
                mkdir $(sed '2,$d' $IPS_TEMP) 
                cp $IPS_TEMP ./$(sed '2,$d' $IPS_TEMP) 
                cd $(sed '2,$d' $IPS_TEMP) 
                grep -i $(sed '2,$d' $IPS_TEMP) ../$ADB_LOCAL |sed '3,$d' |grep -oe "[a-z]\+.[:_ ]\+.[0-9]\+.[-]\+.[0-9]\+.[0-Z]\+" |cut -c 14-29 |sed 's/T/ /g' >$TIME_0 && sed -i 's/$/:00/' $TIME_0
                grep -i $(sed '2,$d' $IPS_TEMP) ../$ADB_LOCAL |sed -n '$p' |grep -oe "[a-z]\+.[:_ ]\+.[0-9]\+.[-]\+.[0-9]\+.[0-Z]\+" |cut -c 14-29 |sed 's/T/ /g' >$TIME_N && sed -i 's/$/:59/' $TIME_N
                editcap -A "$(cat $TIME_0)" -B "$(cat $TIME_N)" $PCAP $SAMPLE_TEMP
                tcpdump -r $SAMPLE_TEMP -w $SAMPLE host $(sed '2,$d' $IPS_TEMP)
                awk 'NR>1{print}' $IPS_TEMP > ../$IPS_TEMP 
                head -n 1 $IPS_TEMP > IP.txt && rm $IPS_TEMP && rm $SAMPLE_TEMP
                cd ..
            done
        done
    }

time_extractor

}

ADBhoney
###################################################################################################################ADBhoney
rclone sync /home/tsec/CHECKS nextcloud:PRUEBA_2 && sleep 60
exit