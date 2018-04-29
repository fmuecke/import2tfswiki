@echo off
setlocal

if not exist devguide (
	md devguide
	cd devguide
	git init
	git config core.sparsecheckout true
	echo DevGuide >> .git/info/sparse-checkout
	git remote add -f origin ssh://tfsmaster:22/tfs/Main/bms/_git/bms
	git pull origin develop
)
