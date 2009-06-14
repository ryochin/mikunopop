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
my $feed_uri = 'http://live.nicovideo.jp/recent/rss?tab=live&sort=start&p=1';
my $status_file = '/web/mikunopop/htdocs/var/live_status.js';

## check feed

my $live = 0;
my ($uri, $title);
if( my $feed = XML::Feed->parse(URI->new( $feed_uri ) ) ){
	for my $entry( $feed->entries ){
		$title = $entry->title;
		next if $title !~ /ミクノポップをきかないか/o;
		
		$uri = $entry->link;
		
		printf STDERR "=> ON AIR: %s by feed.\n", $title;
		$live++;
		last;
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
		
		if( $html =~ m{<div class="live-title"><a href="([^"]+?)" class="community">([^<>]+?)</a>}o ){    # "{
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

<div class="live-title"><a href="http://live.nicovideo.jp/watch/lv1385742" class="community">初音ミク 歌ってみた限定Part.1717</a></div>

