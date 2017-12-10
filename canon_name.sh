#!/bin/sh

dir="$(realpath "$(dirname "$0")")"

parse_info() {
	v=`grep \"$1\" "$dir"/info.json | head -1`
	v="${v%%\",}"
	v="${v##*\"}"
	echo $v
}

name=`parse_info name`
version=`parse_info version`
echo "${name}_${version}"

