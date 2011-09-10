#!/usr/bin/perl --
# ionice -c2 -n7 nice -20 ./script/mikunobot.pl > /dev/null 2>&1 &

use strict;
use warnings;
use lib qw(lib /web/mikunopop/lib);
use Mikunopop::Bot::Basic;

my $bot = Mikunopop::Bot::Basic->new(
	server => "irc.mikunopop.info",
	port   => "6669",
	channels => ["#mikunopop"],
	
	nick      => "mikuno_chan",
	alt_nicks => ["bot", "mikuno_bot"],
	username  => "mikuno_chan",
	name      => "I am mikuno chan!",
	password => 'yatsuhashi',
	
	charset => "utf-8", # charset the bot assumes the channel is using
);
$bot->run;

__END__
