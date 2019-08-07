#!/bin/bash
# This script enables dynamic service discovery without consul agents using heartbeat & elasticsearch
while true
do
# elastic search query string to get all records whose monitor status is down
  STATUS_CHECK_DOWN='{ "query":{ "bool":{ "must":[ { "range" : { "@timestamp" : { "gte" : "now-30s", "lt" : "now" } } }, { "term": { "monitor.status": "down" } } ] } } }'

# curl command string to to get the heartbeat data from elasticsearch in a pretty format ( line by line)
  URL_REQ_STATUS="curl --user cyclotis:cycadmin -s http://192.168.1.28:9200/heartbeat-*/_search?pretty"

# command execution to get the down records from elasticsearch, filter the "Node"s and assign the same to a variable
# grep '"Node"' gets the lines with "Node"; awk '{print $3}' picks the 3rd column in the line which is "Node" name
# awk '{gsub(/,/,""); print}' removes the comma that may appear at the end in some lines. The comma appears because of multiple fields (Node
# & ServiceID) and their order will keep switching in the records
# Note that "Node" and "ServiceID" fields are added in dynamic.json which is periodically loaded by heartbeat config file, heartbeat.yml
# The below statements need to be optimised; we can have a single query to extract pretty data and then filter for Node & ServiceID
  STATUS_DOWN_NODES=$($URL_REQ_STATUS -H 'Content-Type: application/json' -d "$STATUS_CHECK_DOWN" | grep '"Node"'  | awk '{print $3}'| awk '{gsub(/,/,""); print}' )
# command execution to get the node records from elasticsearch, filter the "ServiceID"s and assign the same to a variable
  STATUS_DOWN_SERVICEIDS=$($URL_REQ_STATUS -H 'Content-Type: application/json' -d "$STATUS_CHECK_DOWN" | grep '"ServiceID"'  | awk '{print $3}'| awk '{gsub(/,/,""); print}' )

# echo $STATUS_DOWN_NODES $STATUS_DOWN_SERVICEIDS

if [ -n "$STATUS_DOWN_NODES" ]
then
# for loop to assign Nodes to an array
# the below code needs to be optimised; we can remove one for loop combining one of the array loading and deregistration
# Further optimization: compare elements of arrays together ( eg., deds20 k9) and if there are duplicates, delete them; For this, the first optimization is of no use, since we need to prepare the arrays first and compare them
# The below approach of for loop is the optimal way to loads words in a single line / multi line string to an array
  aindex=0
  for word in ${STATUS_DOWN_NODES}
  do
     nodearray[aindex++]=$word
  done
# for loop to assign ServiceIDs to an array
  aindex=0
  for word in ${STATUS_DOWN_SERVICEIDS}
  do
     idarray[aindex++]=$word
  done
# for loop to take each element from the two arrays to form the data needed for deregistration
  aindex=0
  for word in ${STATUS_DOWN_NODES}
  do
    CURL_STRING='{ "Node": '"${nodearray[aindex]}, "'"ServiceID": '"${idarray[aindex]} }"
#   echo down nodes $CURL_STRING
#   deregister down service in consul catalog
    curl --request PUT --data "$CURL_STRING" http://consul.service.consul:8500/v1/catalog/deregister
    aindex=$((aindex+1))
  done
fi

# elastic search query string to get all records whose monitor status is Up
STATUS_CHECK_UP='{ "query":{ "bool":{ "must":[ { "range" : { "@timestamp" : { "gte" : "now-30s", "lt" : "now" } } }, { "term": { "monitor.status": "up" } } ] } } }'

# command execution to get the down records from elasticsearch, filter the "Node"s and assign the same to a variable
# grep '"Node"' gets the lines with "Node"; awk '{print $3}' picks the 3rd column in the line which is "Node" name
# awk '{gsub(/,/,""); print}' removes the comma that may appear at the end in some lines. The comma appears because of multiple fields (Node
# & ServiceID) and their order will keep switching in the records
# The below statements need to be optimised; we can have a single query to extract pretty data and then filter for Node, ServiceID, ip
  STATUS_UP_NODES=$($URL_REQ_STATUS -H 'Content-Type: application/json' -d "$STATUS_CHECK_UP" | grep '"Node"'  | awk '{print $3}'| awk '{gsub(/,/,""); print}' )
# command execution to get the node records from elasticsearch, filter the "ServiceID"s and assign the same to a variable
  STATUS_UP_SERVICEIDS=$($URL_REQ_STATUS -H 'Content-Type: application/json' -d "$STATUS_CHECK_UP" | grep '"ServiceID"'  | awk '{print $3}'| awk '{gsub(/,/,""); print}' )
# command execution to get the node records from elasticsearch, filter the "ip"s and assign the same to a variable
  STATUS_UP_IPS=$($URL_REQ_STATUS -H 'Content-Type: application/json' -d "$STATUS_CHECK_UP" | grep '"ip"'  | awk '{print $3}'| awk '{gsub(/,/,""); print}' )
if [ -n "$STATUS_UP_NODES" ]
then
# for loop to assign Nodes to an array
# the below code needs to be optimised; we can remove one for loop combining one of the array loading and deregistration
# Further optimization: compare elements of arrays together ( eg., deds20 k9) and if there are duplicates, delete them; For this, the first optimization is of no use, since we need to prepare the arrays first and compare them
  aindex=0
  for word in ${STATUS_UP_NODES}
  do
     nodearray[aindex++]=$word
  done
# for loop to assign ServiceIDs to an array
  aindex=0
  for word in ${STATUS_UP_SERVICEIDS}
  do
     idarray[aindex++]=$word
  done
# for loop to assign ips to an array
  aindex=0
  for word in ${STATUS_UP_IPS}
  do
     iparray[aindex++]=$word
  done
# for loop to take each element from the three arrays to form the data needed for registration
  aindex=0
  for word in ${STATUS_UP_NODES}
  do
    CURL_STRING='{ "Node": '"${nodearray[aindex]}, "'"Address": '"${iparray[aindex]}, "'"Service": { "ID": '"${idarray[aindex]}, "'"Service": '"${idarray[aindex]} } }"
#   echo Up nodes $CURL_STRING
#   register up service in consul catalog
    curl --request PUT --data "$CURL_STRING" http://consul.service.consul:8500/v1/catalog/register
    aindex=$((aindex+1))
  done
fi

  sleep 10
done
