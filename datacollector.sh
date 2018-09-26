#!/bin/bash
data=`date -v-5M +%s000`
query="SELECT * FROM transactions WHERE segments.userData.codigoEstabelecimento IS NOT NULL SINCE $data"
tabela="teste"
log="log.txt"
DEBUG=0

echo "`date +%d-%m-%y_%H:%M:%S` - INFO - INICIO ======= " >> $log
if [ ${DEBUG} == 1 ]
then 
    echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - query=$query" >> $log
fi  

retorno=$(curl -s -o saida.json -w '%{http_code}' -H"X-Events-API-AccountName:semparar_31ad92ff-4bb1-44f0-a429-314e4808b341" -H"X-Events-API-Key:b2f6e4e9-8fe6-4329-89ae-6878fa0a8227" -H"Content-type: application/vnd.appd.events+json;v=2" -X POST "https://analytics.api.appdynamics.com/events/query" -d "$query" )

case $retorno in
    200)
        ;;
    *)
        echo "ERROR: Unable to execute query HTTP code="${retorno}
        echo "`date +%d-%m-%y_%H:%M:%S` - ERROR - Unable to execute query HTTP code=${retorno}" >> $log
        exit 1
        ;;
esac

total_registros=`cat saida.json | jq -c '.[].total'`

if [ ! -z "${total_registros}" ];
then
    echo "`date +%d-%m-%y_%H:%M:%S` - INFO - total_registros=$total_registros" >> $log
    
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
        echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - insert=$insert" >> $log
    fi

    HTTP_CODE=$(curl -s -H"X-Events-API-AccountName:semparar_31ad92ff-4bb1-44f0-a429-314e4808b341" -H"X-Events-API-Key:b2f6e4e9-8fe6-4329-89ae-6878fa0a8227" -H"Content-type: application/vnd.appd.events+json;v=2" -X POST "https://analytics.api.appdynamics.com/events/schema/$tabela" -d '{\"schema\" : {$insert} }' | jq '.statusCode')

    if [ ${DEBUG} == 1 ]
    then 
        echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - insert HTTP_CODE=${HTTP_CODE}" >> $log
    fi
    case ${HTTP_CODE} in
        400|409)
            echo "WARNING: Tabela ja cadastrada"
            echo "`date +%d-%m-%y_%H:%M:%S` - WARNING - Tabela ja cadastrada" >> $log
            ;;
        200)
            ;;
        *)
            echo "ERROR: Unable to create event HTTP code="${HTTP_CODE}
            echo "`date +%d-%m-%y_%H:%M:%S` - ERROR - Unable to Create event HTTP code=${HTTP_CODE}" >> $log
            exit 1
            ;;
    esac

    dados=""

    for ((x=0;x<$total_registros-1;x++))
    do 
        total_arrays=`cat saida.json | jq --arg x $x '.[0].results[$x|tonumber][0]'`
        if [ ${DEBUG} == 1 ]
        then
            echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - x=${x}" >> $log 
            echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - x=${x}"
            echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - total_arrays=${total_arrays}" >> $log
        fi
        for ((y=0;y<$total_arrays-1;y++))
        do
            arrays=`cat saida.json | jq --arg x $x --arg y $y  '.[0].results[$x|tonumber][10][$y|tonumber][17]|length'`
            if [ ${arrays} -ge 15 ] 
            then
                if [ ${DEBUG} == 1 ]
                then 
                    echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - y=${y}" >> $log 
                    echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - y=${y}" 
                    echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG -  arrays=$arrays" >> $log
                fi
                dado="[{"
                vazio=0
                for ((z=0;z<$arrays-1;z++)) 
                do  
                    tamanho=`cat saida.json | jq --arg x $x --arg y $y --arg z $z '.[0].results[$x|tonumber][10][$y|tonumber][17][$z|tonumber]|length'`
                    if [ ${DEBUG} == 1 ]
                    then 
                        echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - z=${z}" >> $log 
                        echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - z=${z}" 
                        echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - tamanho=${tamanho}" >> $log
                    fi
                    if [ ${tamanho} -gt 1 ]
                    then
                        valores=`cat saida.json | jq --arg x $x --arg y $y --arg z $z '.[0].results[$x|tonumber][10][$y|tonumber][17][$z|tonumber][0]'`
                    else
                        valores=`cat saida.json | jq --arg x $x --arg y $y --arg z $z '.[0].results[$x|tonumber][10][$y|tonumber][17][$z|tonumber]'`
                    fi
                    if [ ! -z "${valores}" ];
                    then
                        if [ ${DEBUG} == 1 ]
                        then 
                            echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - z=${z}" >> $log 
                            echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - z=${z}" 
                            echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG -  tamanho=${tamanho}" >> $log
                        fi
                        if [[ $valores = *"Ljava.lang.String"* ]]; then
                            if [ ${DEBUG} == 1 ]
                            then 
                                echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - campo=${campos[$z]} ignorado" >> $log 
                                echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - campo=${campos[$z]} ignorado"
                            fi    
                        else
                            if [ ${DEBUG} == 1 ]
                            then 
                                echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - valores=${valores}" >> $log
                            fi
                            if [ ! $dado == "[{" ];
                            then 
                                dado=$dado"," 
                            fi 
                            dado=$dado${campos[$z]}":"$valores
                        fi
                    else
                        vazio=1
                    fi
                done
                if [ ${vazio} == 0 ] 
                then
                    dado=$dado"}]"
                    if [ ${DEBUG} == 1 ]
                    then 
                        echo "`date +%d-%m-%y_%H:%M:%S` - DEBUG - dado=$dado" >> $log
                    fi
                    retorno=`curl -s -o /dev/null -w '%{http_code}' -H"X-Events-API-AccountName:semparar_31ad92ff-4bb1-44f0-a429-314e4808b341" -H"X-Events-API-Key:b2f6e4e9-8fe6-4329-89ae-6878fa0a8227" -H"Content-type: application/vnd.appd.events+json;v=2" -X POST "https://analytics.api.appdynamics.com/events/publish/$tabela" -d $dado`
                    case $retorno in
                        200)
                            ;;
                        *)
                            echo "ERROR: Unable to create event HTTP code=$retorno"
                            echo "`date +%d-%m-%y_%H:%M:%S` - ERROR - Unable to publish event HTTP code=${retorno}" >> $log
                            break
                            echo "`date +%d-%m-%y_%H:%M:%S` - FIM" >> $log
                            exit 1
                            ;;
                    esac
                else
                    echo "ERROR: Valores vazios x=${x}, y=${y}, z=${z}, campo=${campos[$z]}"
                    echo "ERROR: Valores vazios x=${x}, y=${y}, z=${z}, campo=${campos[$z]}" >> $log
                    cat saida.json | jq --arg x $x '.[0].results[$x|tonumber][10][$y|tonumber]' >> $log
                    echo "`date +%d-%m-%y_%H:%M:%S` - ERROR - Valores Vazios" >> $log
                fi
            fi
        done
    done
else 
    echo "`date +%d-%m-%y_%H:%M:%S` - INFO - Nao ha registros a serem processados" >> $log
fi
echo "`date +%d-%m-%y_%H:%M:%S` - INFO - FIM ==========" >> $log