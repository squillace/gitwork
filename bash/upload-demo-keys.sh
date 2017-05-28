#!/bin/bash

vault=$1


for local_full_key_file in $(ls -d -1 $HOME/.ssh/demo/*)
   do
      key_file=$(basename $local_full_key_file)
      keyvault_key_name=${key_file/\.*/}
      keyvault_key_name=${keyvault_key_name//_/-}
      echo "key_file name: $key_file"
      echo "keyvault secret name: $keyvault_key_name"
# because keyvault creates a URL out of this name, it cannot have a '.' in it. THANKS.
      if [[ $local_full_key_file =~ .*pub ]]; then
            keyvault_key_name="$keyvault_key_name-pub"
      fi      
            az keyvault secret set --vault-name $vault --name $keyvault_key_name --description "acs demo key file: $key_file" --file $local_full_key_file --query "[id,contentType]"

done

