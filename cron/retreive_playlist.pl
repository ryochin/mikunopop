#!/usr/bin/perl --

use strict;
use warnings;
use lib qw(lib /web/mikunopop/lib);
use Path::Class qw(file dir);
use IO::Handle;
use File::Basename;
use List::Util qw(first);
use CGI;
use LWP::Simple qw(get);
use YAML::Syck ();
use Text::CSV_XS;
use Compress::Zlib;

use Mikunopop::VideoInfo;
use Mikunopop::Count;

use utf8;
use Encode;

my $stash = {};

my $base_dir = '/web/mikunopop/';
my $var_dir = file( $base_dir, "var" );
my $htdocs_dir = file( $base_dir, "htdocs" );

my $db_file = file( $var_dir, 'playlist.db' )->stringify;
my $csv_file = file( $htdocs_dir, "play", 'all.csv.gz' )->stringify;
my $json_file = file( $htdocs_dir, "play", 'count.json' )->stringify;
my $text_file = file( $htdocs_dir, "play", 'count.txt' )->stringify;

my $uri_list = [
	'/web/mikunopop/var/playlist/0.html',
	'/web/mikunopop/var/playlist/1.html',
	'/web/mikunopop/var/playlist/2.html',
	'/web/mikunopop/var/playlist/3.html',
	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1304336074/2-',    # 4th
];

#my @ignore = ( @{ $Mikunopop::VideoInfo::Jingle }, @{ $Mikunopop::VideoInfo::Wrong }, @{ $Mikunopop::VideoInfo::Deleted } );
my @ignore = ( @{ $Mikunopop::VideoInfo::Jingle }, @{ $Mikunopop::VideoInfo::Wrong } );

my $content;
for my $uri( @{ $uri_list } ){
	if( $uri =~ /^http/o ){
		# http
		if( my $c = get( $uri ) ){
			printf STDERR "uri: %s: ok.\n", $uri;
			$content .= eval { Encode::decode( 'euc-jp', $c ) } || $c;
		}
		else{
			printf STDERR "uri: %s: failed.\n", $uri;
			die;
		}
	}
	else{
		# file
		my $c = file( $uri )->slurp or die $!;
		$content .= eval { Encode::decode( 'euc-jp', $c ) } || $c;
		printf STDERR "file: %s: ok.\n", $uri;
	}
}

my $ignore = {};    # vid => num
my $video = {};
for my $line( split /\n/o, $content ){
	next if $line !~ /<dt>/o;
	chomp $line;
	$line = CGI::unescapeHTML( $line );
	
	my $seen = {};
	for my $data( split m{<br>}, $line ){
		next if $data !~ /^\s*?[\-]*?\s*?(sm|nm|so)[0-9]{7,8}/o;
		
		$data =~ s/^\s+//o;
		
		# マイナスするものをチェック
		my $ok = $data =~ s/^[\-]+\s*//o
			? 0
			: 1;
		
		# まず空白で切ってみる
		my ($n, $title) = split /[\s\t　]+/o, $data, 2;
		
		# 初期のログには空白で区切られていないものがあるので特別に処理する
		if( $n !~ /^(sm|nm)[0-9]{7,8}$/o ){
			($n, $title) = unpack "A9 A*", $data;
		}
		
		if( not $ok ){
#			printf STDERR"%s\n", eval{ Encode::encode_utf8($data) } || $data;
			$ignore->{ $n }++;
		}
		
		# duplicate check
		next if defined $seen->{ $n };
		$seen->{ $n } = 1;
		
		( my $id = $n ) =~ s/^(sm|nm)+//o;
		
		if( $ok ){
			$video->{ $n }->{num}++;
		}
		else{
			$video->{ $n }->{num}--;
			next;
		}
		
		$video->{ $n }->{id} ||= $id;
		
		# title
		if( defined $title and bytes::length( $title ) > 1 ){
			if( defined $video->{ $n }->{title} ){
				# length
				if( length( $title ) < length $video->{ $n }->{title} ){
					$video->{ $n }->{title} = $title;
				}
			}
			else{
				$video->{ $n }->{title} = $title;
			}
		}
	}
}

#printf STDERR "ignore: %d videos\n", scalar keys %{ $ignore };

printf STDERR "total: %d videos\n", scalar keys %{ $video };

my @video_all;
for my $v( sort { $video->{$b}->{num} <=> $video->{$a}->{num} || $video->{$a}->{id} <=> $video->{$b}->{id} } keys %{ $video } ){
	# ジングル等は飛ばそう
#	next if scalar( first { $v eq $_ } @ignore );
	if( scalar( first { $v eq $_ } @ignore ) ){
		$video->{$v}->{num} = 0;
	}
	
	# その他おかしいものは飛ばす
	next if not defined $video->{$v}->{num};
	next if $video->{$v}->{num} eq '';
	
	# 再生数が０なら飛ばそう
	next if $video->{$v}->{num} < 1;
	
	my $d = {
		id => $v,    # sm1234567
		vid => $video->{$v}->{id},    # 1234567
		title => scalar( $video->{$v}->{title} || q/不明/ ),
		view => $video->{$v}->{num},    # 再生数
	};
	
	# all
	push @video_all, $d;
}

## 補正する

while( my ($id, $offset) = each %{ $Mikunopop::Count::Correction } ){
	$offset = int $offset;
	if( my $video = first { $_->{id} eq $id } @video_all ){
#		printf STDERR "correction: found: %s\n", $id;
		$video->{view} += $offset;
	}
	else{
#		printf STDERR "correction: not found: %s\n", $id;
		push @video_all, {
			id => $id,
			view => $offset,
		};
	}
}

# count.json
{
	my $list;
	for my $v( @video_all ){
		$list->{ $v->{id} } = $v->{view};
	}
	
	require JSON::Syck;
	require DateTime::Format::Mail;
	
	local $JSON::Syck::SortKeys = 1;
	
	# 最終更新日付を入れておく
	$list->{"created-at"} = DateTime::Format::Mail->format_datetime( DateTime->now( time_zone => 'Asia/Tokyo' ) );
	
	my $fh = file( $json_file )->openw or die $!;
	$fh->print( JSON::Syck::Dump( $list ) );
	$fh->close;
}

# count.txt
{
	my $text;
	for my $v( @video_all ){
		$text .= sprintf "%s: %d\n", $v->{id}, $v->{view};
	}
	
	my $fh = file( $text_file )->openw or die $!;
	$fh->print( $text );
	$fh->close;
}

# count.db
{
	# add extra
	for my $id(@{ $Mikunopop::VideoInfo::Extra } ){
		next if first { $_->{id} eq $id } @video_all;
		
		( my $vid = $id ) =~ s/^(sm|nm)+//o;
		push @video_all, {
			id => $id,
			vid => $vid,
			view => 0,
		};
	}
	
	my $fh = file( $db_file )->openw or die $!;
	$fh->print( YAML::Syck::Dump( [ @video_all ] ) );
	$fh->close;
}

# all tsv
{
	my $csv = Text::CSV_XS->new( { binary => 1 } );
	my @csv;
	for my $v( @video_all ){
		$csv->combine( map { Encode::encode('sjis', $_) } @{$v}{qw(view vid title)} );
		push @csv, $csv->string;
	}

	my $fh = file( $csv_file )->openw or die $!;
	$fh->print( Compress::Zlib::memGzip( join "\r\n", @csv ) );
	$fh->close;
}

exit 0;

__END__
