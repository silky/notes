#!/bin/bash

# git-rm-conflicts, version 1.1
#
# by John Wiegley <johnw@newartisans.com>
#
# Run without arguments to see usage.

if [[ -z "$1" ]]; then
    cat <<EOF
usage: git rm-conflicts ours|theirs FILES...

With 'ours', delete conflicts coming from the current branch (aka HEAD).
With 'theirs', delete conflicting code from the commits you're trying to
merge in.

Example:
  $ git checkout master
  $ git merge foo
    <lots of conficts from foo I don't care about>
  $ git rm-conflicts ours FILE1 FILE2
    <delete conflicts in FILE1 and 2, but check the others>

NOTE: You almost never want to use this command, but instead should
check why exactly your files are conflicting.  Use of this script is
almost guaranteed to throw away code you don't want to throw away!!
But if you need it, here it is.
EOF
    exit 1
fi

if [[ "$1" == ours ]]; then
    shift 1
    wipe=ours

elif [[ "$1" == theirs ]]; then
    shift 1
    wipe=theirs

else
    echo error: Must specify which set of changes to remove: ours or theirs
    exit 1
fi

for item in "$@"; do
    if [[ -d "$item" ]]; then
	if [[ $(basename "$item") != .git ]]; then
	    find "$item" \( -name .git -prune -o -type f -print0 \) | \
		xargs -0 $0 $wipe
	fi
    elif [[ -f "$item" ]]; then
	echo Removing $wipe from: $item
	if [[ $wipe == ours ]]; then
	    perl -i -ne 'print unless /<<<<<</ .. /======/ or />>>>>>/;' "$@"
	elif [[ $wipe == theirs ]]; then
	    perl -i -ne 'print unless /<<<<<</ or /======/ .. />>>>>>/;' "$@"
	fi
    else
	echo warning: Ignoring non file/directory '$item'
    fi
done
