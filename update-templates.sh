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
	ttk-get
	git add $(ttk-langs)
	git commit -m "Various: pre templates update"
	ttk-build
	git add $(ttk-langs)
	git commit -m "All: update against templates"
	ttk-put --yes
fi
git push
rm_lock_file
