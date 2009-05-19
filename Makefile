# [Mikunopop Project]
# 
# $URL: svn+ssh://ryo@aquahill.net/home/ryo/svn/fumi2/trunk/Makefile $
# $Id: Makefile 223 2009-05-02 02:29:26Z ryo $

PROJECT = mikunopop
BASE = /web/$(PROJECT)

PERL = /usr/bin/perl -I$(BASE)/lib -I$(BASE)/extlib
NICE = /bin/nice -10
SH = /bin/sh

all:: install

install::
	$(NICE) $(PERL) install/installer.pl -q
	chmod 755 $(BASE)/cron/*.pl > /dev/null 2>&1

