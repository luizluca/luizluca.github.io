Since CC (15.05), OpenWRT check for signatures.
In order to use this repo, add the Packages.key to the trusted keyring:

 cd /tmp
 wget http://luizluca.github.io/openwrt/15.05/ar71xx/packages/Packages.key
 /bin/usign -F -p Packages.key
 rm Packages.key
