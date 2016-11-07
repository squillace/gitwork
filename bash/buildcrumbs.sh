#!/bin/bash

GITROOT=$(git rev-parse --show-toplevel)
BREAD_DIR=$(find "$GITROOT" -type d -name "bread")
DOCSET_ROOT=$(find "$GITROOT" -type d -name "azure")
CONTENT_ROOT=$(find "$GITROOT" -type d -name "articles")
BREAD_FILE=TOC.yml

echo "GITROOT: $GITROOT"
echo "BREAD_DIR: $BREAD_DIR"
echo "DOCSET_ROOT: $DOCSET_ROOT"
echo "BREAD_FILE: $(ls $BREAD_DIR)"

DIRS=$(find $CONTENT_ROOT -type d -d 1)

#rm $BREAD_DIR/$BREAD_FILE

echo "- name: Azure" # >> $BREAD_DIR/$BREAD_FILE
echo "  tocHref: /azure"
echo "  topicHref: /azure/index"
echo "  items:"

#- name: SAP on Azure
#  href: /azure/articles/sap
#  homepage: /azure/articles/sap/index

for DIR in $DIRS
do
    DIR_FRAGMENT=$(echo $DIR | sed "s/\/Users\/rasquill\/workspace\/azure-docs-pr\/articles//g")
    echo "  - name: $(basename $DIR | gsed -e "s/\b\(.\)/\u\1/g" | tr - ' ')"

    # grab the first entry in the TOC file
    homeURL=$(grep -oP -m 1 "(?<=\]\().+(?=\.md\))" "$DIR/TOC.md")
    #echo "$homeURL"

    echo "    tocHref: /azure$DIR_FRAGMENT/" # >> 
    echo "    topicHref: /azure$DIR_FRAGMENT/$homeURL"
done





#- name: SAP on Azure
#  href: /azure/sap
#  homepage: /azure/sap/index
#- name: Linux Virtual Machines
#  href: /azure/virtual-machines/
#  homepage: /azure/vm-landing
#- name: Storage
#  href: /azure/storage/
#  homepage: /azure/storage/storage-azure-cli
#  items:
#  - name: How to use Azure File Storage with Linux
#    href: /azure/storage/storage-how-to-use-files-linux
#    homepage: /azure/storage/storage-how-to-use-files-linux
#- name: Virtual Network
#  href: /azure/virtual-network/
#  homepage: /azure/virtual-network/virtual-network-overview
#- name: Guidance
#  href: /azure/guidance/
#  homepage: /azure/guidance/guidance-compute-single-vm-linux%