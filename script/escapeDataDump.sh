#!/bin/sh
for i in db/*.txt; do sed -r -f escapeSpecials.sed -i $i; done
