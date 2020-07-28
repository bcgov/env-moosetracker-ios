#!/bin/sh

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input PDF>"
  exit 1
fi

pdftk "$1" cat 1-27 output general.pdf
pdftk "$1" cat 28-34 output region_1.pdf
pdftk "$1" cat 35-42 output region_2.pdf
pdftk "$1" cat 43-47 output region_3.pdf
pdftk "$1" cat 48-57 output region_4.pdf
pdftk "$1" cat 58-64 output region_5.pdf
pdftk "$1" cat 65-72 output region_6.pdf
pdftk "$1" cat 73-78 output region_7a.pdf
pdftk "$1" cat 79-85 output region_7b.pdf
pdftk "$1" cat 86-90 output region_8.pdf
pdftk "$1" cat 91-97 output trapping.pdf
