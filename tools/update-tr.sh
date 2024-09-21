#!/bin/bash

find -name 'mod.conf' | while read modconf; do
	moddir=$(dirname "$modconf")
	mtt_convert.py --po2tr "$moddir"
	mod_translation_updater.py "$moddir"
	mtt_convert.py --tr2po "$moddir"
done
