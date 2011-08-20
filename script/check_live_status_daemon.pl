#!/usr/bin/perl --
# 

use strict;
use warnings;
use Path::Class qw(dir file);
use App::Daemon ();

use Furl;
use XML::Feed;
use JSON::Syck ();
local $JSON::Syck::ImplicitUnicode = 1;

use utf8;
use Encode ();

my $community_uri = 'http://ch.nicovideo.jp/community/co13879';
my $feed_uri = 'http://live.nicovideo.jp/recent/rss?tab=req&sort=start&p=1';
my $status_file = '/web/mikunopop/htdocs/var/live_status.js';
my $wait = 60;    # sec

my $base_dir = dir("/web/mikunopop");
my $var_dir = dir( $base_dir, "var" );

# setup
local $App::Daemon::logfile = file( $var_dir, "check_live_status_daemon.log" );
local $App::Daemon::pidfile = file( $var_dir, "check_live_status_daemon.pid");

App::Daemon::daemonize();

while(1){
	## check feed
	
	my $live = 0;
	my ($uri, $title);
	do {
		my $furl = Furl->new;
		my $res = $furl->get( $feed_uri );
		if( $res->is_success ){
			my $content = $res->content;
			# たまに壊れた xml を送りつけられるので、手動でなんとかする
			$content =~ s{^(.+?)<\?xml version="1.0" encoding="utf-8"\?>.+?$}{$1}so;
			
			if( my $feed = XML::Feed->parse( \ $content ) ){
				for my $entry( $feed->entries ){
					$title = $entry->title;
					next if $title !~ /ミクノポップを(き|聞|聴)かないか/o;
					next if $title =~ /アイマス/o;
					
					$uri = $entry->link;
					$uri =~ s{\?ref=community$}{};
					
					printf STDERR "=> ON AIR: %s by feed.\n", $title;
					$live++;
					last;
				}
			}
		}
		else{
			printf STDERR "=> cannot get feed!\n";
		}
	};

	## check html
	
	if( not $live ){
		sleep 2;
		my $furl = Furl->new;
		my $res = $furl->get( $community_uri );
		if( $res->is_success ){
			my $content = $res->content;
			$content = eval { Encode::decode_utf8( $content ) } || $content;
			
			# <h2><a href="http://live.nicovideo.jp/watch/lv10304992" class="community">ミクノポップをきかないか？Part3339</a></h2>
			if( $content =~ m{<h2><a href="(http://live\.nicovideo\.jp/[^"]+?)" class="community">([^<>]+?)</a>}o ){    # "{
				($uri, $title) = ($1, $2);
				$uri =~ s{\?ref=community$}{};
				
				printf STDERR "=> ON AIR: %s by html.\n", $title;
				$live++;
			}
		}
		else{
			printf STDERR "=> cannot get html!\n";
		}
	}
	
	## output
	
	if( $live ){
		&write_status( { status => 1, uri => $uri, title => $title } );
	}
	else{
		printf STDERR "=> no live.\n";
		&write_status( { status => 0 } );
	}
	
	sleep $wait;
}

sub write_status {
	my $hash = shift or return;

	my $fh = file( $status_file )->openw or die $!;
	$fh->print( Encode::encode_utf8( JSON::Syck::Dump( $hash ) ), "\n" );
	$fh->close;
}

__END__

<h2 class="now_live_titl"><a href="http://live.nicovideo.jp/watch/lv2722574" class="community">ミクノポップをきかないか？Part1613</a></h2><div id="box">

