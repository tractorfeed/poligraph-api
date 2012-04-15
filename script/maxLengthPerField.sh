#!/bin/sh
for i in db/*; do awk -f fieldLengths.awk -F"|" $i > $i.length; done
