#!/bin/sh

ZIP='7z'
cd "$(dirname "$0")"
zipfile="$(./canon_name.sh).zip"

include=`
cat <<- END
	LICENSE
	info.json
	*.lua
	*.md
END
`

cd "$dir"
dirs=`ls -d */`

echo "Zipping to $zipfile :"
for f in $include $dirs
do
	echo $f
done
echo
"$ZIP" a -r "$zipfile" $include $dirs