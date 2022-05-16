#!/bin/bash
set -e

mkdir -p /usr/lib/enigma2/python/Plugins/Extensions/OpenWebif
cp -rp ./plugin/* /usr/lib/enigma2/python/Plugins/Extensions/OpenWebif/
for f in $(find ./locale -name *.po ); do
	l=$(echo ${f%} | sed 's/\.po//' | sed 's/.*locale\///')
	mkdir -p /usr/lib/enigma2/python/Plugins/Extensions/OpenWebif/locale/${l%}/LC_MESSAGES
	msgfmt -o /usr/lib/enigma2/python/Plugins/Extensions/OpenWebif/locale/${l%}/LC_MESSAGES/OpenWebif.mo ./locale/$l.po
done

