#!/bin/bash

set -e
set -o pipefail

tmpfile=./util/update_structs_thomas

./util/update_lists.pl
perl -ple 's{/usr}{$ENV{HOME}/usr}' ./util/update_structs.pl > $tmpfile
chmod +x $tmpfile
$tmpfile
rm -f $tmpfile
./util/update_versions.pl

#exit 0

perl Makefile.PL INC="-I/soe/tnijssen/usr/include" LIBS="-L/soe/tnijssen/usr/lib/x86_64-linux-gnu -lX11 -lXtst -lXext -lXcomposite -lXfixes -lXrender" OPTIMIZE="-g"
make -j8

