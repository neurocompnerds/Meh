#!/bin/bash

find *.sharedKeys.NC.vcf > fileList.txt
cut -f1 -d"." fileList.txt > id.txt
paste id.txt fileList.txt > meh.txt
while read id vcf; do
    cp vcfHeader.txt $id.muchMoreBettererVcf.vcf
    head -n1 $vcf | cut -f 124-133 >> $id.muchMoreBettererVcf.vcf
    sed '1d' $vcf | cut -f 1-10 >> $id.muchMoreBettererVcf.vcf
done < meh.txt
rm meh.txt id.txt fileList.txt
echo "booyah! FTFY"
