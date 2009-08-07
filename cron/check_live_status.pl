#!/usr/bin/perl --

use strict;
use LWP::Simple qw(get);
use HTML::TokeParser;
use Path::Class qw(file);
use JSON::Syck;
local $JSON::Syck::ImplicitUnicode = 1;
use XML::Feed;

use utf8;
use Encode;

my $community_uri = 'http://ch.nicovideo.jp/community/co13879';
my $feed_uri = 'http://live.nicovideo.jp/recent/rss?tab=req&sort=start&p=1';
my $status_file = '/web/mikunopop/htdocs/var/live_status.js';

## check feed

my $live = 0;
my ($uri, $title);
if( my $content = get( $feed_uri  ) ){
	# たまに壊れた xml を送りつけられるので、手動でなんとかする
	$content =~ s{^(.+?)<\?xml version="1.0" encoding="utf-8"\?>.+?$}{$1}so;
	
	if( my $feed = XML::Feed->parse( \ $content ) ){
		for my $entry( $feed->entries ){
			$title = $entry->title;
			next if $title !~ /ミクノポップを(き|聞|聴)かないか/o;
			
			$uri = $entry->link;
			
			printf STDERR "=> ON AIR: %s by feed.\n", $title;
			$live++;
			last;
		}
	}
}
else{
	printf STDERR "=> cannot get feed!\n";
}

## check html

if( not $live ){
	sleep 2;
	if( my $html = LWP::Simple::get( $community_uri ) ){
		$html = Encode::decode_utf8( $html );
		
		if( $html =~ m{<h2 class\="now_live_title*"><a href="([^"]+?)" class="community">([^<>]+?)</a>}o ){    # "{
			($uri, $title) = ($1, $2);
			
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

sub write_status {
	my $hash = shift or return;

	my $fh = file( $status_file )->openw or die $!;
	$fh->print( Encode::encode_utf8( JSON::Syck::Dump( $hash ) ), "\n" );
	$fh->close;
}

__END__

<h2 class="now_live_titl"><a href="http://live.nicovideo.jp/watch/lv2722574" class="community">ミクノポップをきかないか？Part1613</a></h2><div id="box">

