from curses.ascii import ctrl
import os

pack = ""
lists = ""
for l in os.listdir("/usr/share/enigma2/po"):
	if ".po" in l:
		continue
	pack += """Package: enigma2-locale-%s
Version: 7.1
Depends: enigma2
Status: install ok installed
Architecture: all
Installed-Size: 186628
Installed-Time: 1652135548
Auto-Installed: yes

""" % (l)

	ctl = """Package: enigma2-locale-%s
Version: 7.1
Description: %s
 %s
Section: base
Priority: optional
Maintainer: OE-Alliance
License: GPLv2
Architecture: all
OE: enigma2
Depends: enigma2
Source: enigma2.bb

""" % (l, l, l)

	with open("/var/lib/opkg/info/enigma2-locale-%s.control" % l, "w") as fd:
		fd.write(ctl)
		fd.flush()

lists += ctl

pack += """Package: enigma2-plugin-skins-metrix-atv-fhd-icons
Version: 7.1
Depends: enigma2
Status: install ok installed
Architecture: all
Installed-Size: 186628
Installed-Time: 1652135548
Auto-Installed: yes

"""

ctl = """Package: enigma2-plugin-skins-metrix-atv-fhd-icons
Version: 7.1
Description: enigma2-plugin-skins-metrix-atv-fhd-icons
 enigma2-plugin-skins-metrix-atv-fhd-icons
Section: base
Priority: optional
Maintainer: OE-Alliance
License: GPLv2
Architecture: all
OE: enigma2
Depends: enigma2
Source: enigma2.bb

"""

with open("/var/lib/opkg/info/enigma2-plugin-skins-metrix-atv-fhd-icons.control", "w") as fd:
	fd.write(ctl)
	fd.flush()

with open("/var/lib/opkg/status", "w") as fd:
	fd.write(pack)
	fd.flush()

with open("/var/lib/opkg/lists/openatv-all", "w") as fd:
	fd.write(pack)
	fd.flush()

'''
Package: enigma2-locale-de
Version: 7.0+git31245+a39c8c5-r0
Description: de
 de
Section: base
Priority: optional
Maintainer: OE-Alliance
License: GPLv2
Architecture: vusolo4k
OE: enigma2
Depends: enigma2
Source: enigma2.bb
Filename: enigma2-locale-de_7.0+git31245+a39c8c5-r0_vusolo4k.ipk
Size: 156584
MD5Sum: 930e07893f4d52c3afc1867d7a469804

'''