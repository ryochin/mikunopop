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

