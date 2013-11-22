#!/bin/sh
for i in `find ./|sed 's/^\.\/.*\/\..*//'|sed -n -e '/pl$/p' -e '/pm$/p'`;   
do cat $i|wc -l -w -m; 
done|awk '{ 
    sum1 = sum1 + $1; 
    sum2 = sum2 + $2; 
    sum3 = sum3 + $3;
    } 
    END { 
	printf "%d;;%d;;%d", sum1, sum2, sum3;
	}'
