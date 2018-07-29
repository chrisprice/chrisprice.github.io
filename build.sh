#!/bin/bash
set -e

tmp=.tmp

npm install --silent --global --prefer-offline --prefix $tmp marky-markdown@12.0.0

for directory in `find blog -depth 4`;
do
	source=$directory/index.md
	target=$directory/index.html
	title=`head -n 1 $source`
	tail -n +3 $source > $tmp/index.md
	content=`./$tmp/bin/marky-markdown $tmp/index.md`
	cat _layouts/default.html \
		| awk -v title="$title" '{gsub(/\$title/,title)}1' \
		| awk -v content="${content//$'\n'/\\n}" '{gsub(/\$content/,content)}1' \
		> $target
done
