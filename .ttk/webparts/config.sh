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
LANGS_WITH_ALL_FILES="af an as bn_BD br bs ca cak cy en_ZA ff ga_IE hi_IN is lt lv nb_NO ne sat son ta ur xh"


# List of files that are always enabled for translation.
MINIMUM_COMMON_FILES="download_button.lang
firefox/accounts.lang
firefox/all.lang
firefox/channel/index.lang
firefox/new/horizon.lang
firefox/sync.lang
main.lang
mozorg/404.lang
mozorg/about.lang
mozorg/home/index-2016.lang
mozorg/mission.lang
mozorg/plugincheck-redesign.lang
mozorg/products.lang
mozorg/technology.lang
newsletter.lang
privacy/principles.lang
tabzilla/tabzilla.lang"
