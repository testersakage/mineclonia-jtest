#!/bin/sh
world=mcla_generate_translations
mtdir=../../../..
wdir=$mtdir/worlds/$world
if [ ! -x $1 ]; then
	echo mtt_updater not found at $1 pass the python script as first argument!
	exit 1
fi

if [ ! -x $mtdir/bin/minetest ]; then
	echo This script needs to be run from the tools/generate_translation_strings directory within a run_in_place minetest
	exit 1
fi

if [ -d $mtdir/worlds/$world ]; then
	echo Temp world $world already exists. Remove or rename it to run this script.
	exit 1
fi

mkdir -p $wdir/worldmods
cp -r mcla_generate_translation_strings $wdir/worldmods
echo "gameid = mineclonia" > $wdir/world.mt
echo -n Running minetest to extract complex translation strings...
$mtdir/bin/minetest --server --gameid mineclonia --worldname $world > /dev/null 2>&1
if [ -f $wdir/mcla_translate/mod_dirs.txt ]; then
	echo done
else
	echo Running minetest did not produce any translation files.
	echo The temporary world directory has been preserved so the situation can be investigated:
	echo You can delete it by running rm -rf $wdir
	exit 1
fi
cat $wdir/mcla_translate/mod_dirs.txt |while read f; do
	mod=$(echo $f|cut -d " " -f1)
	file=$(echo $f|cut -d " " -f2)
	echo cp $wdir/mcla_translate/$file $mod
done
#$1 -r ../../mods
cat $wdir/mcla_translate/mod_dirs.txt |while read f; do
	mod=$(echo $f|cut -d " " -f1)
	file=$(echo $f|cut -d " " -f2)
	echo rm $mod/$file
done
rm -rf $wdir
echo Mod translation strings have been extracted and updated. You will now want to create a new commit containing the new translation strings
