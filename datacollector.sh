#!/bin/bash
data=`date -v-4H +%s000`
query="SELECT * FROM transactions WHERE segments.userData.codigoEstabelecimento IS NOT NULL SINCE $data"
tabela="teste"
log="log.txt"
DEBUG=0


echo "Inicio: `date +%d-%m-%y_%H:%M:%S`" >> $log
curl -s -H"X-Events-API-AccountName:semparar_31ad92ff-4bb1-44f0-a429-314e4808b341" -H"X-Events-API-Key:b2f6e4e9-8fe6-4329-89ae-6878fa0a8227" -H"Content-type: application/vnd.appd.events+json;v=2" -X POST "https://analytics.api.appdynamics.com/events/query" -d "$query"> saida.json

total_registros=`cat saida.json | jq -c '.[].total'`
if [ ${DEBUG} == 1 ]
then 
    echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG: total_registros=$total_registros" >> $log
fi

read -r -a campos <<< `cat saida.json | jq -c '.[0].fields[] | select ( .label == "segments") | .fields[] | select ( .field == "userData" ) | .fields[].field'`

read -r -a tipos <<< `cat saida.json | jq -c '.[0].fields[] | select ( .label == "segments") | .fields[] | select ( .field == "userData" ) | .fields[].type'`

insert=""
for ((i=0;i<${#campos[@]};i++))
do
    if [ ${i} -ne 0 ] 
    then 
        insert=$insert"," 
    fi 
   insert=$insert${campos[$i]}":"${tipos[$i]}
done
if [ ${DEBUG} == 1 ]
then 
    echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG: insert=$insert" >> $log
fi

HTTP_CODE=$(curl -s -H"X-Events-API-AccountName:semparar_31ad92ff-4bb1-44f0-a429-314e4808b341" -H"X-Events-API-Key:b2f6e4e9-8fe6-4329-89ae-6878fa0a8227" -H"Content-type: application/vnd.appd.events+json;v=2" -X POST "https://analytics.api.appdynamics.com/events/schema/$tabela" -d "{\"schema\" : {$insert} }" | jq '.statusCode')

if [ ${DEBUG} == 1 ]
then 
    echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG: insert HTTP_CODE=${HTTP_CODE}" >> $log
fi
case ${HTTP_CODE} in
	409)
        echo "WARNING: Tabela ja cadastrada"
        echo "`date +%d-%m-%y_%H:%M:%S` - WARNING: Tabela ja cadastrada" >> $log
        ;;
    200)
        ;;
    *)
        echo "ERROR: Unable to create event HTTP code="${HTTP_CODE}
        break
        echo "`date +%d-%m-%y_%H:%M:%S` - ERROR: Unable to create event HTTP code=${HTTP_CODE}" >> $log
        exit 1
        ;;
esac

dados=""

for ((x=0;x<$total_registros;x++))
do 
    total_arrays=`cat saida.json | jq --arg x $x '.[0].results[$x|tonumber][0]'`
    if [ ${DEBUG} == 1 ]
    then 
        echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG: total_arrays=${total_arrays}" >> $log
    fi
    for ((y=0;y<$total_arrays;y++))
    do
        arrays=`cat saida.json | jq --arg x $x --arg y $y  '.[0].results[$x|tonumber][10][$y|tonumber][17]|length'`
        if [ ${arrays} -ge 15 ] 
        then
            if [ ${DEBUG} == 1 ]
            then 
                echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG: arrays=$arrays" >> $log
            fi
            dado=""
            for ((z=0;z<$arrays;z++)) 
            do
                tamanho=`cat saida.json | jq --arg x $x --arg y $y --arg z $z '.[0].results[$x|tonumber][10][$y|tonumber][17][$z|tonumber]|length'`
                if [ ${DEBUG} == 1 ]
                then 
                    echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG: tamanho=${tamanho}" >> $log
                fi
                if [ ${tamanho} -ge 1 ]
                then
                    valores=`cat saida.json | jq --arg x $x --arg y $y --arg z $z '.[0].results[$x|tonumber][10][$y|tonumber][17][$z|tonumber][0]'`
                else
                    valores=`cat saida.json | jq --arg x $x --arg y $y --arg z $z '.[0].results[$x|tonumber][10][$y|tonumber][17][$z|tonumber]'`
                fi
                if [ ${DEBUG} == 1 ]
                then 
                    echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG: valores=${valores}" >> $log
                fi
                if [ ${z} -ne 0 ] 
                then 
                    dado=$dado"," 
                fi 
                dado=$dado${campos[$z]}":"$valores
            done
            if [ ${DEBUG} == 1 ]
            then 
                echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG: dado=$dado" >> $log
            fi
            HTTP_CODE=$(curl -s -H"X-Events-API-AccountName:semparar_31ad92ff-4bb1-44f0-a429-314e4808b341" -H"X-Events-API-Key:b2f6e4e9-8fe6-4329-89ae-6878fa0a8227" -H"Content-type: application/vnd.appd.events+json;v=2" -X POST "https://analytics.api.appdynamics.com//events/publish/$tabela" -d "[{$dado}]"| jq '.statusCode')
            case ${HTTP_CODE} in
                200)
                    ;;
                *)
                    echo "ERROR: Unable to create event HTTP code="${HTTP_CODE}
                     echo "`date +%d-%m-%y_%H:%M:%S` - ERROR: Unable to create event HTTP code=${HTTP_CODE}" >> $log
                    break
                    echo "Fim: `date +%d-%m-%y_%H:%M:%S`" >> $log
                    exit 1
                    ;;
            esac
        fi
    done
done
echo "Fim: `date +%d-%m-%y_%H:%M:%S`" >> $log