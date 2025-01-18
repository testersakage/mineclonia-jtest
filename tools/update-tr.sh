#!/bin/bash

# assumes to be started in mineclonia top level directory and that Luanti's mod
# tools and Wuzzy's translation tools are in PATH

# run all steps two times for a complete roundtrip of changed translations
for i in 0 1; do
    ltt_convert.py mods --po2tr -r
    tools/generate_translation_strings/generate.sh mod_translation_updater.py
    ltt_convert.py mods --tr2po -r
done

# makes sure at least one translation file is present for every mod so it can
# be detected by weblate; there is probably a cleaner way to do this
find -name poconvert | while read poconvert; do
	if (( $(ls "$poconvert" | wc -l) == 1 )); then
		sed 's/"Language: /"Language: fr/' "$poconvert/template.pot" > "$poconvert/fr.po"
		echo "Created new translation file in $poconvert"
	fi
done
