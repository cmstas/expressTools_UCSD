#! /bin/bash

while read line; do
	printf "[ %28s ]:  %s\n" "`date`" "$line"  
done