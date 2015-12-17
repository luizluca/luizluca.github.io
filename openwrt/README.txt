Since CC (15.05), OpenWRT check for signatures.
In order to use this repo, add the Packages.key to the trusted keyring:

 cd /tmp
 wget http://luizluca.github.io/openwrt/fe8e1e6731dc3f26
 opkg-key add fe8e1e6731dc3f26
 rm fe8e1e6731dc3f26
