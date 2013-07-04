#!/bin/bash

source ttk.inc.sh

langs=$(which_langs $*)
log_info "Processing languages '$langs'"

function update_source() {
	log_info "Updating '$SOURCE_DIR'"
	if [ ! -d $SOURCE_DIR/.svn ]; then
		svn co $svnverbosity $MOZREPONAME/projects/mozilla.com/trunk/en-GB $SOURCE_DIR
	else
		svn up $svnverbosity $SOURCE_DIR
	fi
}

function revert_active_header() {
	# Revert the ## active ## header that is added by the covertor
	# We want to retain whatever was there before our update
	# FIXME remove this from non-added files also
	local lang=$1
	log_info "Reverting ## active ## header to upstream state"
	cd $TARGET_DIR/$lang
	for file in $(find . -name "*.lang")
	do
		if [ "$(svn diff $file 2>/dev/null | egrep "^[+-]## active ##$")" ]; then
			cp $file $file.bak
			if [ "$(svn diff $file | egrep "^[+]## active ##$")" ]; then
				tail -n +2 $file.bak > $file

			else
				echo "## active ##" | cat - $file.bak > $file
			fi
			rm $file.bak
		fi
	done
}

function revert_blank_line_only_changes() {
	# Revert files with only blank line changes
	local mozlang=$1
	log_info "Reverting blank line only changes in '${TARGET_DIR}/${mozlang}'"
	cd $TARGET_DIR/$mozlang
        [ -d ${TARGET_DIR}/${mozlang}/.svn ] && svn revert $(svn diff --diff-cmd diff -x "--unified=3 --ignore-blank-lines -s" ${TARGET_DIR}/${mozlang} |
        egrep "are identical$" |
        sed "s/^Files //;s/\(\.lang[^\/]\).*/\1/")
}

log_info "Updating first level of '$TARGET_DIR'"
if [ ! -d $TARGET_DIR/.svn ]; then
	svn co $svnverbosity --depth=files $MOZREPONAME/projects/mozilla.com/trunk/ $TARGET_DIR
else
	svn up $svnverbosity --depth=files $TARGET_DIR
fi

for lang in $langs
do
	log_info "Processing language '$lang'"
	polang=$(get_language_pootle $lang)
	if [ "$polang" == "templates" ]; then
		update_source
		rm -rf $POT_DIR
		mkdir -p $POT_DIR/firefox/channel/
		(cd $SOURCE_DIR 
		php2po --errorlevel=$errorlevel --progress=$progress firefox/channel/index.html $POT_DIR/firefox/channel/index.po
		html2po --errorlevel=$errorlevel --progress=$progress firefox/channel/content.inc.html $POT_DIR/firefox/channel/content.inc.po
		)
		podebug --errorlevel=$errorlevel --progress=$progress --rewrite=blank $POT_DIR $POT_DIR
		for po in $(find $POT_DIR -name "*.po")
		do
			mv $po ${po}t
		done
		revert_unchanged_po_git $POT_DIR/.. templates
	else
		mozlang=$(get_language_upstream $lang)
		verbose "Migrate - update PO files to new POT files"
		tempdir=`mktemp -d tmp.XXXXXXXXXX`
		if [ -d ${PO_DIR}/${polang} ]; then
			cp -R ${PO_DIR}/${polang} ${tempdir}/${polang}
			(cd ${PO_DIR}/${polang}; rm $(find . -type f -name "*.po"))
		fi
		pomigrate2 --use-compendium --pot2po $pomigrate2verbosity ${tempdir}/${polang} ${PO_DIR}/${polang} ${POT_DIR}
		# FIXME we should revert stuff that wasn't part of this migration e.g. mobile
		rm -rf ${tempdir}

		clean_po_location $PO_DIR $polang
		revert_unchanged_po_git $PO_DIR $polang

		svn revert $svnverbosity -R $TARGET_DIR/$mozlang
		svn up $svnverbosity $TARGET_DIR/$mozlang
		rm -f $(find $TARGET_DIR/$mozlang -name "*.lang")
		# FIXME If we don't ouput anything we might want to restore what is there already
		po2php --threshold=50 --exclude="templates" --errorlevel=$errorlevel --progress=$progress -t $SOURCE_DIR $PO_DIR/$polang $TARGET_DIR/$mozlang
		revert_active_header $mozlang
		revert_blank_line_only_changes $mozlang
	fi
done
