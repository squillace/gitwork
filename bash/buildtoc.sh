#!/bin/bash

while IFS=, read ID TOC_FILES FILE TITLE SERVICE SERVICE_SLUG AUTHOR PILLAR DIRECTORY TOP_NODE NODE_2_TOC NODE_3_TOC COMMENTS
do
   
   echo "::$ID::, ::$TOC_FILES::, ::$FILE::, ::$TITLE::, ::$SERVICE::, ::$SERVICE_SLUG,:: ::$AUTHOR::, ::$PILLAR::, ::$DIRECTORY::, ::$TOP_NODE::, ::$NODE_2_TOC::, ::$NODE_3_TOC::, ::$COMMENTS::"
   
done <<< $(cat toc.txt)