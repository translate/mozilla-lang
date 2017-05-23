#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import sys


# Default that can be overriden when calling the script.
SOURCE_DIR = '/home/dwayne/mozilla/web_parts/source/'


def get_mozgit_langs():
    """Return list of languages in Mozilla's Mozilla.org git repository."""
    langs = next(os.walk(SOURCE_DIR))[1]
    langs.remove('en-US')
    langs.remove('hi')  # Special directory with too few files.
    langs.remove('.git')
    return sorted(langs)


def get_mozgit_files_for(lang):
    """Return files list for a language in Mozilla's Mozilla.org git repo."""
    lang_dir = os.path.join(SOURCE_DIR, lang, "")
    lang_dir_len = len(lang_dir)
    result = []
    for (dirpath, _dirnames, fnames) in os.walk(lang_dir):
        dirpath = dirpath[lang_dir_len:]
        for fname in fnames:
            if not fname.endswith(".lang"):
                continue
            relfname = fname
            if len(dirpath) > 1:
                relfname = os.sep.join([dirpath, relfname])
            if relfname not in result:
                result.append(relfname)
    return sorted(result)


def get_mozgit_common_files():
    """Return list of common files for all langs in Mozilla.org git repo."""
    os.chdir(SOURCE_DIR)
    all_files = get_mozgit_files_for("en-US")
    for lang in get_mozgit_langs():
        lang_files = get_mozgit_files_for(lang)
        if not lang_files:
            continue
        all_files = [fname
                     for fname in all_files
                     if fname in lang_files]
    all_files = sorted(all_files)
    print(" ".join(all_files))


if __name__ == "__main__":
    if len(sys.argv) == 2 and os.path.exists(sys.argv[1]):
        SOURCE_DIR = sys.argv[1]  # Override default.
        get_mozgit_common_files()
