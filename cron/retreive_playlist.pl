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

use utf8;
use Encode;

my $stash = {};

my $base_dir = '/web/mikunopop/';
my $var_dir = file( $base_dir, "var" );
my $htdocs_dir = file( $base_dir, "htdocs" );

my $db_file = file( $var_dir, 'playlist.db' )->stringify;
my $csv_file = file( $htdocs_dir, "play", 'all.csv.gz' )->stringify;
my $json_file = file( $htdocs_dir, "play", 'count.json' )->stringify;

my $uri_list = [
	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1235658251/29-400',
	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1243754024/2-',
];

# ジングル
my @jingle = qw(
	sm6789292
	sm6789315
	sm6939234
	sm6981084
	sm7007629
	sm7033805
	sm7075450
	sm7246105
	sm7346152
	sm7539134
	sm7539326
	sm7870758
	sm7891336
	sm8009643
	sm8031848
	sm8032058
	sm8138979
	sm8183423
	sm8230401
	sm8311828
	sm7335402
	sm7337914
	sm7341325
	sm7343558
	sm7346152
	sm7473981
	sm8145136
	sm8432973
	sm8569861
	sm8588518
	sm8611151
);

# 明らかにおかしいもの
my @ignore = qw(
	sm7382119
	sm1200617
);

my $content;
for my $uri( @{ $uri_list } ){
	if( my $c = get( $uri ) ){
		printf STDERR "uri: %s: ok.\n", $uri;
		$content .= eval { Encode::decode( 'euc-jp', $c ) } || $c;
	}
	else{
		printf STDERR "uri: %s: failed.\n", $uri;
	}
	sleep 1;
}

my $ignore = {};    # vid => num
my $video = {};
for my $line( split /\n/o, $content ){
	next if $line !~ /<dt>/o;
	chomp $line;
	$line = CGI::unescapeHTML( $line );
	
	my $seen = {};
	for my $data( split m{<br>}, $line ){
		next if $data !~ /^\s*?[\-]*?\s*?(sm|nm)[0-9]{7,8}/o;
		
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

printf STDERR "ignore: %d videos\n", scalar keys %{ $ignore };

my @video_all;
for my $v( sort { $video->{$b}->{num} <=> $video->{$a}->{num} || $video->{$a}->{id} <=> $video->{$b}->{id} } keys %{ $video } ){
	# 再生数が０なら飛ばそう
	next if $video->{$v}->{num} < 1;
	
	# ジングルは飛ばそう
#	next if scalar( first { $v eq $_ } @jingle );
	if( scalar( first { $v eq $_ } @jingle ) ){
		$video->{$v}->{num} = 0;
	}
	
	# 告知動画なども飛ばそう
#	next if scalar( first { $v eq $_ } @ignore );
	if( scalar( first { $v eq $_ } @ignore ) ){
		$video->{$v}->{num} = 0;
	}
	
	# すでに削除されているものを飛ばす
	next if first { $v eq $_ } @{ $Mikunopop::VideoInfo::Deleted };
	
	# その他おかしいものは飛ばす
	next if not defined $video->{$v}->{num};
	next if $video->{$v}->{num} eq '';
	
	my $d = {
		id => $v,    # sm1234567
		vid => $video->{$v}->{id},    # 1234567
		title => scalar( $video->{$v}->{title} || q/不明/ ),
		view => $video->{$v}->{num},    # 再生数
	};
	
	# all
	push @video_all, $d;
}

# count.json
{
	my $list;
	for my $v( @video_all ){
		$list->{ $v->{id} } = $v->{view};
	}
	
	require JSON::Syck;
	require DateTime::Format::Mail;
	
	# 最終更新日付を入れておく
	my $json = sprintf "// %s\n", DateTime::Format::Mail->format_datetime( DateTime->now( time_zone => 'Asia/Tokyo' ) );
	$json .= JSON::Syck::Dump( $list );
	
	my $fh = file( $json_file )->openw or die $!;
	$fh->print( $json );
	$fh->close;
}

# count.db
{
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
