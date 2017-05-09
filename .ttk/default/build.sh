#!/bin/bash

source ttk.inc.sh

langs=$(which_langs $*)
log_info "Processing languages '$langs'"

function update_source() {
	log_info "Updating '$SOURCE_DIR'"
	if [ ! -d $SOURCE_DIR/.git ]; then
		git clone https://github.com/mozilla-l10n/www.mozilla.org.git $SOURCE_DIR
	else
		cd $SOURCE_DIR
		git reset --hard
		git pull
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

function handle_new_and_empty_dirs() {
	# Remove empty dirs and add new ones
	local mozlang=$1
	log_info "Processing new/empty directories in '${TARGET_DIR}/${mozlang}'"
	(cd $TARGET_DIR/$mozlang/
	for dir in $(svn status . | egrep "^\?")
	do
		if [ ! -d $dir ]; then
			continue
		fi
		if [ "$(find $dir -type f -true)" ]; then
			log_debug "We found a file, so 'svn add $dir'"
			svn add $dir
		else
			log_debug "We found no files, so 'rm -rf $dir'"
			rm -rf $dir
		fi
	done
	)


}

for lang in $langs
do
	log_info "Processing language '$lang'"
	polang=$(get_language_pootle $lang)
	if [ "$polang" == "templates" ]; then
		update_source
		rm -rf $POT_DIR
		mkdir -p $POT_DIR/templates/mozorg/emails
		(cd $SOURCE_DIR/en-US
		moz2po --errorlevel=$errorlevel --progress=$progress . $POT_DIR
		txt2po --errorlevel=$errorlevel --progress=$progress templates/mozorg/emails $POT_DIR/templates/mozorg/emails
		)
		podebug --errorlevel=$errorlevel --progress=$progress --rewrite=blank $POT_DIR $POT_DIR
		for po in $(find $POT_DIR -name "*.po")
		do
			mv $po ${po}t
		done
		rm $POT_DIR/templates/mozorg/emails/*.txt  # Cleanup files that moz2po copied
		clean_po_location $PO_DIR $polang
		revert_unchanged_po_git $POT_DIR/.. templates
	else
		mozlang=$(get_language_upstream $lang)
		verbose "Migrate - update PO files to new POT files"
		tempdir=`mktemp -d tmp.XXXXXXXXXX`
		if [ -d ${PO_DIR}/${polang} ]; then
			cp -R ${PO_DIR}/${polang} ${tempdir}/${polang}
			rm -rf ${PO_DIR}/${polang}/*
		fi
		pomigrate2 --use-compendium --pot2po $pomigrate2verbosity ${tempdir}/${polang} ${PO_DIR}/${polang} ${POT_DIR}
		# FIXME we should revert stuff that wasn't part of this migration e.g. mobile
		rm -rf ${tempdir}

		clean_po_location $PO_DIR $polang
		revert_unchanged_po_git $PO_DIR $polang

		# FIXME disabled this as Mozilla upstream is just using our PO
		# files not the .lang files, so no need to back process.
		#svn revert $svnverbosity -R $TARGET_DIR/$mozlang
		#svn up $svnverbosity $TARGET_DIR/$mozlang
		#rm -f $(find $TARGET_DIR/$mozlang -name "*.lang")
		# FIXME If we don't ouput anything we might want to restore what is there already
		#po2moz --threshold=50 --exclude="templates" --errorlevel=$errorlevel --progress=$progress -t $SOURCE_DIR $PO_DIR/$polang $TARGET_DIR/$mozlang
		#mkdir -p $TARGET_DIR/$mozlang/templates/mozorg/emails
		#po2txt --threshold=90 --errorlevel=$errorlevel --progress=$progress -t $SOURCE_DIR/templates/mozorg/emails $PO_DIR/$polang/templates/mozorg/emails $TARGET_DIR/$mozlang/templates/mozorg/emails
		#revert_active_header $mozlang
		#revert_blank_line_only_changes $mozlang
		#handle_new_and_empty_dirs $mozlang
	fi
done
