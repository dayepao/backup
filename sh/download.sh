#!/bin/bash
while read fileurl filename
do
wget -c "$fileurl" -O $filename
done < list.txt
while read fileurl filename
do
sha1sum $filename
done < list.txt