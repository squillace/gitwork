#!/bin/bash

if [[ $# == 0 ]]; then
    echo "You must specify 1) a resource group and 2) a domain zone."
    exit 1
fi


rg=$1
domainZone=$2
recordName=$3
newIP=$4
#echo "$rg"
#echo "$domainZone"

if [[ $3 == "" && $4 == "" ]]; then
    az network dns record-set list -g $rg -z $domainZone -o json --query "[?type=='Microsoft.Network/dnszones/A'].{\"aRecordName\":name,\"IP\":arecords[0].ipv4Address}"
    exit 0
fi

if [[ $3 != "" && $4 == "" ]]; then
    az network dns record-set list -g $rg -z $domainZone -o json --query "[?type=='Microsoft.Network/dnszones/A' && name=='$recordName'].{\"aRecordName\":name,\"IP\":arecords[0].ipv4Address}[0]"
    exit 0
fi

if [[ $3 != "" && $4 != "" ]]; then
    echo "gonna change the IP of: "
    echo ""
    jsonARecord=$(az network dns record-set list -g $rg -z $domainZone -o json --query "[?type=='Microsoft.Network/dnszones/A' && name=='$recordName'].{\"aRecordName\":name,\"IP\":arecords[0].ipv4Address}[0]")
    echo "$jsonARecord"
    echo ""
    az network dns record-set a delete -g $rg -z $domainZone -n "$recordName" && az network dns record-set a add-record --ipv4-address $newIP --record-set-name "$recordName" -g $rg -z $domainZone
fi
