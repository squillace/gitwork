#!/bin/bash

vault=$1
path=$2

if [[ $path == "" ]]; then
        path="$HOME/.ssh"
fi

#az keyvault secret list --vault-name rasquill-vault --query "[].id" -o tsv 
#| sed "s/.*\///g" 
#| xargs -I {} az keyvault secret download --name {} --vault-name rasquill-vault --file $(${{}//-pub/foo})

if [[ ! -d $path/demo ]]; then
    echo "making $path/demo"
    mkdir -p $path/demo
fi

for key_file in $(az keyvault secret list --vault-name $vault --query "[].id" -o tsv | sed "s/.*\///g")
   do
        written_key_file=${key_file//-/_}
        echo $written_key_file
        if  [[ $written_key_file =~ .*pub ]]; then
            written_key_file=${written_key_file//_pub/.pub}
            echo "we have a pub file, so we'll put it at $path/demo/$written_key_file"
        fi
        az keyvault secret download --name $key_file --vault-name $vault --file $path/demo/$written_key_file
done

