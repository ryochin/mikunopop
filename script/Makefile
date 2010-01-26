
NUM = 3000

all:: convert

convert:
	nice -20 perl ./create_comment_html.pl -n $(NUM)
	nice -20 perl ./create_comment_calendar.pl
	nice -20 perl ./create_comment_index.pl

convert-all:
	nice -20 perl ./create_comment_html.pl
	nice -20 perl ./create_comment_calendar.pl
	nice -20 perl ./create_comment_index.pl
