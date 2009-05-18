all: create upload

create:
	nice -10 perl ./mikuno_count.pl

upload:
	scp -C ./mikuno_count.pl diana:/home/ryo/cron/
	scp -C ./mikunopop_jingle.pl diana:/home/ryo/cron/
#	scp -C ./mikunopop.html diana:/web/saihane/htdocs/
	scp -C ./css/* diana:/web/saihane/htdocs/css/
	scp -C ./js/* diana:/web/saihane/htdocs/js/

clean:
	rm -f mikunopop.html
