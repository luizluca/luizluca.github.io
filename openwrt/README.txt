Since CC (15.05), OpenWRT check for signatures.
In order to use this repo, add it to custom repo and the Packages.key to the trusted keyring:

 eval $(cat /etc/os-release)
 wget -O /tmp/luizluca.key http://luizluca.github.io/$ID/fe8e1e6731dc3f26
 opkg-key add /tmp/luizluca.key
 rm /tmp/luizluca.key
 echo "src/gz luizluca-$ID http://luizluca.github.io/$ID/packages-$VERSION_ID/$LEDE_ARCH" >>/etc/opkg/customfeeds.conf

