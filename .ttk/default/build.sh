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

function get_language_files() {
	MOZ_GIT_DIR=$1
	if [ -d ${MOZ_GIT_DIR} ]
	then
		# Language in Mozilla's git repository, so craft the list from git repository.
		LANG_MOZ_GIT_FILES=""
		cd $MOZ_GIT_DIR
		for langfile in $(find ./ -type f -name '*.lang' | sort)
		do
			# Strip "./" prefix from the filenames.
			LANG_MOZ_GIT_FILES+=" ${langfile:2}"
		done
		echo $LANG_MOZ_GIT_FILES
	else
		# Language not in Mozilla's git repository. Defaulting to minimum common files.
		echo $MINIMUM_COMMON_FILES
	fi
}

function remove_files() {
	# Go to the specified directory and remove all files not in language files.
	LANGUAGE_DIR=$1
	if [ ! -d ${LANGUAGE_DIR} ]
	then
		log_info "Directory '${LANGUAGE_DIR}' doesn't exist. Skipping it."
		return
	fi
	cd $LANGUAGE_DIR

	# Need to use this to get all the passed args except the first one.
	LANGUAGE_FILES=${*:2}

	log_info "Processing '${LANGUAGE_DIR}'"
	log_info "============"
	for pofile in $(find ./ -type f -name '*.po' | sort)
	do
		# Strip "./" prefix and ".po" extension from filename.
		langfile=${pofile:2:-3}

		# Process only files not in language files.
		if [[ ! " ${LANGUAGE_FILES[*]} " == *$langfile* ]]
		then
			echo "    ${pofile:2}"
			rm -f ${pofile:2}
		fi
	done
}


for lang in $langs
do
	log_info "Processing language '$lang'"
	polang=$(get_language_pootle $lang)
	if [ "$polang" == "templates" ]; then
		update_source
		rm -rf $POT_DIR
		mkdir -p $POT_DIR
		(cd $SOURCE_DIR/en-US
		moz2po --errorlevel=$errorlevel --progress=$progress . $POT_DIR
		)
		podebug --errorlevel=$errorlevel --progress=$progress --rewrite=blank $POT_DIR $POT_DIR
		for po in $(find $POT_DIR -name "*.po")
		do
			mv $po ${po}t
		done
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

		# If language is in list of languages that shouldn't be touched, then skip it.
		if [[ " ${LANGS_WITH_ALL_FILES[*]} " == *$lang* ]]
		then
			log_info "'${lang}' is marked as language with all files. Skipping files removal."
			continue
		else
			log_info "Removing extra files for '${lang}'."

			# Get list of language files, either from Mozilla's git repo or from minimum common files list.
			LANGUAGE_FILES=$( get_language_files $SOURCE_DIR/${mozlang}/ )

			# Remove unnecessary files for this language.
			MLO_GIT_DIR="${PO_DIR}/${lang}/"
			PODIRECTORY="/var/www/sites/mozilla/translations/mozilla_lang/${lang}/"

			remove_files ${MLO_GIT_DIR} ${LANGUAGE_FILES}
			remove_files ${PODIRECTORY} ${LANGUAGE_FILES}
		fi

		clean_po_location $PO_DIR $polang
		revert_unchanged_po_git $PO_DIR $polang

		# FIXME disabled this as Mozilla upstream is just using our PO
		# files not the .lang files, so no need to back process.
		#svn revert $svnverbosity -R $TARGET_DIR/$mozlang
		#svn up $svnverbosity $TARGET_DIR/$mozlang
		#rm -f $(find $TARGET_DIR/$mozlang -name "*.lang")
		# FIXME If we don't ouput anything we might want to restore what is there already
		#po2moz --threshold=50 --exclude="templates" --errorlevel=$errorlevel --progress=$progress -t $SOURCE_DIR $PO_DIR/$polang $TARGET_DIR/$mozlang
		#revert_active_header $mozlang
		#revert_blank_line_only_changes $mozlang
		#handle_new_and_empty_dirs $mozlang
	fi
done
