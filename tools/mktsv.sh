#!/bin/bash

nametrain=train.tsv
namedev=dev.tsv
nametest=test.tsv

tot=$(cd clips; echo *.mp3|wc -w)
train=$((($tot * 70)/100))
dev=$((($tot * 15)/100))
test=$(($tot - $train - $dev))

echo $tot=$train+$dev+$test

head()
{
    # keep real tabs below
    echo "client_id	path	sentence	up_votes	down_votes	age	gender	accent"
}

i=0
cd clips
head > ../$nametrain
head > ../$namedev
head > ../$nametest
while read n line ; do 
    [ -z "$n" ] && continue
    for f in $n*mp3; do
        name=${f%%.mp3}
        who=${name#*-}
        
        i=$((i+1))
        if [ $i -le $train ]; then
            out=$nametrain
        elif [ $i -le $(($train+$dev)) ]; then
            out=$namedev
        else
            out=$nametest
        fi
        echo "$(echo $i | sha512sum | sed 's, .*,,g')	$f	\"$line\"	100	0	30	$who	france" >> ../$out
    done
done < ../list.txt

cut -d\  -f2- < ../list.txt > ../vocabulary.txt
