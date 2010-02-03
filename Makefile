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

rsync: rsync-htdocs rsync-lib rsync-cron rsync-template

rsync-htdocs:
	rsync -avz ./htdocs/ ryo@selene.aquahill.net:/web/mikunopop/htdocs/

rsync-lib:
	rsync -avz ./lib/ ryo@selene.aquahill.net:/web/mikunopop/lib/

rsync-cron:
	rsync -avz ./cron/ ryo@selene.aquahill.net:/web/mikunopop/cron/

rsync-template:
	rsync -avz ./template/ ryo@selene.aquahill.net:/web/mikunopop/template/

git-add-comment-html:
	git add var/comment/meta.yml
	git add var/comment/*/**
	git add htdocs/comment/*/**
	git add htdocs/comment/index.html

upload:
	rsync -avz -e ssh lib/Mikunopop/ diana:/web/mikunopop/lib/Mikunopop/
	rsync -avz -e ssh template/ diana:/web/mikunopop/template/

login:
	nice -10 mysql -umikunopop -pmikunopop mikunopop

# EOF
