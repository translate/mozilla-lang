project=mozilla_lang
instance=mozilla
user=pootlesync
server=mozilla.locamotion.org
local_copy=$base_dir/.pootle_tmp
phaselist=
manage_command="/var/www/sites/$instance/src/manage.py"
manage_py_verbosity=2
precommand=". /var/www/sites/mozilla/env/bin/activate;"
local_trans_dir=$base_dir
opt_verbose=3

SOURCE_DIR="${base_dir}/source"
TARGET_DIR=${base_dir}/build/translations
PO_DIR=${base_dir}
POT_DIR=${PO_DIR}/templates
LANGS=$*
#MOZREPONAME="http://svn.mozilla.org"
MOZREPONAME="svn+ssh://dwayne%40translate.org.za@svn.mozilla.org"
svnverbosity=""

alt_src="bn_IN es es_MX fr ru"


# List of languages we skip when removing extra files because they have significantly translated those.
#LANGS_WITH_ALL_FILES="af an as bn_BD br bs ca cak cy en_ZA ff ga_IE hi_IN is lt lv ne son ta ur xh"
LANGS_WITH_ALL_FILES=""
