# [Mikunopop Project]
# 

PROJECT = mikunopop
BASE = /web/$(PROJECT)

PERL = /usr/bin/perl -I$(BASE)/lib -I$(BASE)/extlib
NICE = /bin/nice -10
SH = /bin/sh

all:: install

install::
	$(NICE) $(PERL) install/installer.pl -q
	chmod 755 $(BASE)/cron/*.pl > /dev/null 2>&1

manifest::
	find . -not -type dl -not -name '\.DS_*' | egrep -v  '\.(svn|git)' | egrep '^[a-zA-Z0-9-/_.]+$$' \
	| egrep -v '^\.$$' | sed -e 's!^./!!g' | sort > ./MANIFEST

xmllint:
	find ./htdocs/ -name '*html' | xargs xmllint --html --noout

