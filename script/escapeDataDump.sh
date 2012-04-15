#!/bin/sh
if grep -q '"""' db/*.txt
  then echo "Source data contains quoting we cannot handle.  Get a proper data santization library."
  exit 1
fi

for i in db/*.txt; do sed -r -f escapeSpecials.sed -i $i; done
