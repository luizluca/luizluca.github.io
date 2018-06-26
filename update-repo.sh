#!/bin/bash

set -e 

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
#GPGKEY="D1073B56"
USIGN=~/prog-local/openwrt/trunk/staging_dir/host/bin/usign
#USIGN=~/prog-local/lede/trunk/staging_dir/host/bin/usign
USIGN_KEY=~/Dropbox/prog/openwrt/key-build
TEMPFILE=$(mktemp -t update-repo.sh.XXXXXXXX)
trap "rm -f '$TEMPFILE'" EXIT
cd $DIR
for rep in $(find $DIR -type d -path "$DIR/openwrt/*/*/packages") $(find $DIR -type d -path "$DIR/openwrt/packages-*/*" ) $(find $DIR -type d -path "$DIR/lede/*/*"); do
    echo Updating $rep
    (   
        cd $rep
        $DIR/ipkg-make-index.sh . > "$TEMPFILE"
		if cmp -s "$TEMPFILE" Packages; then
			echo "No change on Packages. ignore."
			continue
		fi
		trap "rm -f Packages Packages.gz Packages.sig Packages.key" EXIT
		rm -f Packages Packages.gz Packages.sig Packages.key
		cp "$TEMPFILE" Packages
        gzip --no-name -c Packages > Packages.gz
		#gpg2 --local-user $GPGKEY --output Packages.sig --armor --detach-sign Packages
		#gpg --export-options export-clean --output Packages.key --export --armor $GPGKEY
		$USIGN -S -m Packages -s ${USIGN_KEY}
		cp ${USIGN_KEY}.pub Packages.key
		trap - EXIT
    )
done
rm -f "$TEMPFILE"
trap - EXIT

$DIR/filelist.html.sh openwrt
$DIR/filelist.html.sh lede
