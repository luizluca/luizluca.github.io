#!/bin/bash

for DIR; do
	echo Generating Filelist index pages for $DIR...
	find "$DIR" -type d | while read SUBDIR; do
		(
			echo "$SUBDIR/index.html..."
			cd "$SUBDIR"
			cat >index.html <<EOF
<html>
	<header>
		<title>$SUBDIR</title>
	</header>
	<body>
		<a href='..'>[Parent]</a><br>
$(
	ls -1 --color=never --group-directories-first -p | grep -v '.*~' | while read FILE; do
		echo \
"		<a href='$FILE'>$FILE</a><br>"
	done
)		
	</body>
</html>	
EOF
		)
	done
done
