#!/bin/sh
(
 cd $(dirname $(which $0))
 ~/prog-local/openwrt/attitude_adjustment/scripts/ipkg-make-index.sh . 2>&1 > Packages &&
 gzip -9c Packages > Packages.gz
)
