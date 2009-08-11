#!/usr/bin/perl --

use strict;
use warnings;
use lib qw(lib /web/mikunopop/lib);
use Mikunopop::Bot::Basic;

my $bot = Mikunopop::Bot::Basic->new(
	server => "irc.mikunopop.info",
	port   => "6667",
	channels => ["#test"],
	
	nick      => "mikuno_chan",
	alt_nicks => ["bot", "mikuno_bot"],
	username  => "mikuno_chan",
	name      => "I am mikuno chan!",
	
	charset => "utf-8", # charset the bot assumes the channel is using
);
$bot->run;

__END__
