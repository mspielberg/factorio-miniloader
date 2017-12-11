#!/bin/sh

ZIP='7z'

moddir="$(realpath $(dirname "$0"))"
tmpdir=$(mktemp -d)
canon_name="$("$moddir/canon_name.sh")"
zipfile="$PWD/$canon_name.zip"
ln -nsf "$moddir" "$tmpdir/$canon_name"
cd "$tmpdir"

include=$(
cat <<- END
	$canon_name/LICENSE
	$canon_name/info.json
	$canon_name/*.lua
	$canon_name/*.md
END
)


dirs=$(ls -d "$canon_name"/*/ | grep -vF "$canon_name/$canon_name")

echo "Zipping to $zipfile:"
for f in $include $dirs
do
	echo $f
done
echo

"$ZIP" a "$zipfile" $include $dirs
