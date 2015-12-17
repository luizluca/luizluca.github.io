#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
#GPGKEY="D1073B56"
USIGN=~/prog-local/openwrt/trunk/staging_dir/host/bin/usign
USIGN_KEY=~/prog/openwrt/key-build

cd $DIR
for rep in $(find $DIR -path "$DIR/openwrt/*/*/packages"); do
    echo Updating $rep
    (   
        cd $rep
        $DIR/ipkg-make-index.sh . > Packages.new
		if cmp -s Packages.new Packages; then
			echo "Resultado igual. Ignorando..."
			rm Packages.new
			continue
		fi
		rm -f Packages Packages.gz Packages.sig Packages.key
		mv Packages.new Packages
        gzip --no-name -c Packages > Packages.gz
		#gpg2 --local-user $GPGKEY --output Packages.sig --armor --detach-sign Packages
		#gpg --export-options export-clean --output Packages.key --export --armor $GPGKEY
		$USIGN -S -m Packages -s ${USIGN_KEY}
		cp ${USIGN_KEY}.pub Packages.key
    )
done
$DIR/filelist.html.sh openwrt
