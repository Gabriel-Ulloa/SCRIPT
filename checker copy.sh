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
temp_2=$(mktemp)
#
mkdir $DIR_CHECK && cp $COWRIE_JSON $DIR_CHECK
cp $PCAP $DIR_CHECK
cd $DIR_CHECK && mkdir VirusTotal
#
cat $COWRIE_JSON |grep -i $FILE_DOWNLOAD |grep -oe $IP_REGEX |grep -oe $HIP_REGEX | sort | uniq >$temp_1
cat $COWRIE_JSON |grep -i $FILE_UPLOAD |grep -oe $IP_REGEX |grep -oe $HIP_REGEX | sort | uniq >>$temp_1
sed '/^$/d' $temp_1 > $IPS_FOUND
#
function hash_vt(){
file="HASHES.txt"
counter=0
while IFS= read -r hash; do
    #Consultando hash por hash
    echo "consultando..." && /home/tsec/SCRIPT/vt file $hash --format json > VirusTotal/$(echo $hash)_"$(date +"%Y-%m-%d_%H:%M:%S")".json && sleep .5
    counter=$((counter + 1))
    #Verificar si se han revisado doscientas líneas
    if ((counter % 200 == 0)); then
        echo "Esperando 1 minuto..."
        sleep 60
    fi
done < "$file"
}
#
while true 
do
    for file in $IPS_FOUND; do
        if [ ! -s "$file" ]; then
            echo "El archivo $file está vacío. Saliendo del bucle..."
            rm $IPS_FOUND && cat $temp_2 | sort | uniq > HASHES.txt
            hash_vt
            sleep 10
            rclone sync /home/tsec/CHECKS nextcloud:PRUEBA_tsec
            exit
        fi
        echo "Direccciones IP encontradas" #AQUI COMIENZA EL BUCLE 
        mkdir $(sed '2,$d' $IPS_FOUND) #HACE UNA CARPETA CON EL NOMBRE DE LA PRIMER IP DEL DOCUMENTO IPS
        cp $COWRIE_JSON ./$(sed '2,$d' $IPS_FOUND) #COPIA cowrie.json ORIGINAL Y A LA CARPETA RECIEN CREADA ^
        cp $IPS_FOUND ./$(sed '2,$d' $IPS_FOUND) #COPIA EL ARCHIVO IPS A LA CARPETA ^
        cd $(sed '2,$d' $IPS_FOUND) #SE MUEVE DENTRO DE LA CARPETA FCREADA
        #SE BUSCA LA IP ENCONTRADA EN CUESTION Y SE HACE LA BUSQUEDA DE LOS TIEMPOS 0 Y N DE INTERACCION Y SE LE AGREGA LOS MILISEGUNDOS 
        cat $COWRIE_JSON |grep -i $(sed '2,$d' $IPS_FOUND) |sed '2,$d' |grep -oe $TIME_REGEX |cut -c 13-34 |sed 's/T/ /g' >$TIME_0 && sed -i 's/$/:00/' $TIME_0
        cat $COWRIE_JSON |grep -i $(sed '2,$d' $IPS_FOUND) |sed -n '$p' |grep -oe $TIME_REGEX |cut -c 13-34 |sed 's/T/ /g' >$TIME_N && sed -i 's/$/:59/' $TIME_N
        #SE HACE EL RECORTE DEL PCAP CON LOS TIEMPOS OBTENIDOS DE LA IP ANALIZADA EN cowrie.json ^
        editcap -A "$(cat $TIME_0)" -B "$(cat $TIME_N)" $PCAP $SAMPLE #se crea un pcap con el nombre sample
        awk 'NR>1{print}' $IPS_FOUND >../$IPS_FOUND #BORRA LA IP OBTENIDA Y DEJA LAS DEMAS IPS PARA CONTINUAR EL BUCLE CON LAS IPS RESTANTES
        head -n 1 $IPS_FOUND >IP.txt && rm $IPS_FOUND #DEJA UN ARCHIVO IP.txt SOLO CON LA IP ENCONTRADA
        grep $(cat IP.txt) cowrie.json |grep .downl |grep -oe "[shasum]\+.[:]\+.[0-z]\+" |cut -c 10-74 | sort | uniq >HASH.txt 
        cat HASH.txt >> $temp_2
        cd ..
    done
done
