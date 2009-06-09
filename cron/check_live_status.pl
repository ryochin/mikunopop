#!/usr/bin/perl --

use strict;
use LWP::Simple qw(get);
use HTML::TokeParser;
use Path::Class qw(file);
use JSON::Syck;
local $JSON::Syck::ImplicitUnicode = 1;

use utf8;
use Encode;

my $community_uri = 'http://ch.nicovideo.jp/community/co13879';
my $status_file = '/web/mikunopop/htdocs/var/live_status.js';

my $html = get $community_uri or die "cannot get html!";
$html = Encode::decode_utf8( $html );

if( $html =~ m{<div class="live-title"><a href="([^"]+?)" class="community">([^<>]+?)</a>}o ){    # "
	my ($uri, $title) = ($1, $2);
	printf STDERR "=> ON AIR: %s\n", $title;
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

