#!/usr/bin/perl --
# nice -20 ./script/mikunobot.pl > /dev/null 2>&1 &

use strict;
use warnings;
use lib qw(lib /web/mikunopop/lib);
use Mikunopop::Bot::Basic;

my $bot = Mikunopop::Bot::Basic->new(
	server => "selene.aquahill.net",
	port   => "6667",
	channels => ["#test"],
	
	nick      => "mikuno_chan2",
	alt_nicks => ["bot", "mikuno_bot2"],
	username  => "mikuno_chan2",
	name      => "I am mikuno chan!",
	
	charset => "utf-8", # charset the bot assumes the channel is using
);
$bot->run;

__END__
