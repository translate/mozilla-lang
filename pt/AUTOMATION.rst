Local update of firefox dir and local dir
Setup virtualenv and ttk-* commands

Do this every 3/6/12/24? hours:

.. highlight: bash::

   if not templates-updating
   	touch templates-updating
   git pull - we want to be on the latest commit
   ttk-build templates
   using git status --porcelain
   	git add templates
   	git rm templates/ stuff that was deleted
   git commit -m "Templates: update"
   git push - if it fails can we revert and start again?
   	if failed drop last commit
   ttk-push templates
   touch templates-updated - so we can trigger language update against templates
   rm templates-updating


Languages updates
-----------------
Do every hour?

.. highlight: bash::

   if [ current-ttk-get ] then report problem
   git pull - we want to be at the latest commit
   ttk-changeid > current-ttk-get
   ttk-get $last-ttk-get
   git add $(ttk-langs $last-ttk-get)
   git commit -m "ROBOT: Various: pull from Pootle: $lang"
   mv current-ttk-get last-ttk-get

Special handling for a new language being added?
   git commit -m "ROBOT: $lang: initialised

   if [ templates-updated ]
   for lang in ttk-langs - ignore $alt_src langs
      ttk-changeid > $lang-current-ttk-get
      ttk-get $lang
      ttk-build - since last changeid
      git add $(ttk-langs)
      git rm stuff that was deleted
      git commit -m "ROBOT: Various: update against templates"
      ttk-put --keep $lang-current-ttk-get

If we remove our last commit flag then we do a full ttk-get

Issues
- Could we do something that would allow us to manage change in VC being pushed
  to Pootle?
  - If we could know which commits we missed and what files where impacted we
    could determine if we need to update that specific file
