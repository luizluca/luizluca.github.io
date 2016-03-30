#!/bin/bash

FILENAMESIZE=90
FMT="%10s %-${FILENAMESIZE}s %-25s %-10s %s\n"

for DIR; do
	echo Generating Filelist index pages for $DIR...
	find "$DIR" -type d | while read SUBDIR; do
		(
			echo "$SUBDIR/index.html..."
			cd "$SUBDIR"
			cat >index.html <<EOF
<html>
	<header>
		<title>Index of $SUBDIR</title>
	</header>
	<body>
		<h1>Index of $SUBDIR</h1>
		<pre>
<BR>
$(
	find -maxdepth 1 -not -name ".*" -not -name "index.html" -not -name "*~" -printf "%M;%f;%TY-%Tm-%Td %TH:%TM:%2.2TS;%s;%l\n" | sort |
	awk -vFMT="$FMT" -F';' '
	BEGIN {
		printf "<b>" FMT "</b>", "Permission", "Name", "Last modified", "Size", "Description", "Link"
		print "<HR>"
		FILE="[Parent]"
		FILE = "<a href=\"..\">" FILE "</a>" sprintf ( "%" '${FILENAMESIZE}'-length(FILE) "s", "")
		printf FMT, "drwxr-xr-x", FILE, "-", "-", "", ""
	}
	{
		PERM = $1
		FILE = $2
		MOD	 = $3
		"numfmt --to=iec-i --suffix=B " $4 | getline SIZE;
		if ($5) {
			DESC = "-> " $5
			TGT = $5
		} else {
			DESC = ""
			TGT = $1
		}
		FILE = "<a href=\"" TGT "\">" FILE "</a>" sprintf ( "%" '${FILENAMESIZE}'-length(FILE) "s", "")
		printf FMT, PERM, FILE, MOD, SIZE, DESC
	}'
)
<hr>
$( [ -f README.txt ] && cat README.txt  )
		</pre>
	</body>
</html>	
EOF
		)
	done
done
