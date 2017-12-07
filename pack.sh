#!/bin/sh

ZIP='7z'
dir="$1"

parse_info() {
	v=`grep \"$1\" "$dir"/info.json | head -1`
	v="${v%%\",}"
	v="${v##*\"}"
	echo $v
}

include=`
cat <<- END
	LICENSE
	info.json
	*.lua
	*.md
END
`

dirs=`ls -d $dir/*/`

name=`parse_info name`
version=`parse_info version`
zipfile="${name}_${version}.zip"

echo $include
for i in $include
do
	"$ZIP" a -r "$zipfile" "$dir/$i"
done

for i in $dirs
do
	"$ZIP" a -r "$zipfile" "$i"
done