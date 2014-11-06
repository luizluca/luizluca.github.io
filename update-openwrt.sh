#!/bin/bash

./filelist.html.sh openwrt
for rep in openwrt/*/*/packages/; do
    echo Updating $rep
    (   
        cd $rep
        ~/prog-local/openwrt/bb/scripts/ipkg-make-index.sh . > Packages
        gzip -c Packages > Packages.gz
    )
done
