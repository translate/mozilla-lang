#!/bin/bash

source $(dirname $0)/../firefox/ttk.inc.sh
stop_if_running
mk_lock_file

ttk-build templates
git add -A templates
git diff --quiet --cached --exit-code templates
if [ $? -ne 0 -o "$1" == "--force" ]; then
	git commit -m "Templates: update" templates
	ttk-put --yes templates
	id=$(ttk-changeid)
	for lang in $(ttk-langs)
	do
		ttk-get $lang
		git add $lang
		git commit -m "[$lang] pre templates update"
		ttk-build $lang
		git add -A $lang
		git commit -m "[$lang] update against templates"
		ttk-put --yes $lang
	done
fi
git push
rm_lock_file
