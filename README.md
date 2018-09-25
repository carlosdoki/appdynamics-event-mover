# AppDynamics Event Mover

AppDynamics Event Mover.

## Parameters

Periodo a ser consultado
Ex. 
Ultimos 5min
``data=`date -v-5M +%s000` ``

Ultima 1Hora
``data=`date -v-1H +%s000` ``

Query a ser consultada no Analytics
``query="SELECT * FROM transactions WHERE segments.userData.codigoEstabelecimento IS NOT NULL SINCE $data" ``

Nome da Tabela a ser criada no Events
``tabela="teste"``
