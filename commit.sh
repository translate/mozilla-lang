#!/bin/bash

source $(dirname $0)/../firefox/ttk.inc.sh
stop_if_running
mk_lock_file

langs=$(which_langs $*)

for lang in $langs
do
	mozlang=$(get_language_upstream $lang)
	pootlelang=$(get_language_pootle $lang)
	ttk-get $pootlelang
	git add -A $pootlelang
	git commit -m "[$pootlelang] pull from Pootle"
done
git push
rm_lock_file
