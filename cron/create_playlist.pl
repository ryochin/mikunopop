#!/usr/bin/perl --

use strict;
use warnings;
use Path::Class qw(file dir);
use IO::Handle;
use File::Basename;
use List::Util qw(first);
use CGI;
use Template;
use DateTime;
use LWP::Simple qw(get);
use Getopt::Std;
use Text::CSV_XS;
use Compress::Zlib;
use YAML::Syck ();
use JSON::Syck ();

use bytes ();

use utf8;
use Encode;

# getopt
Getopt::Std::getopts 't' => my $opt = {};

my $stash = {};

my $base_dir = '/web/mikunopop/';
my $htdocs_dir = file( $base_dir, "htdocs" );
my $var_dir = file( $base_dir, "var" );

my $db_file = file( $var_dir, 'count.yml' )->stringify;

my $output_file_csv = file( $htdocs_dir, "play", 'all.csv.gz' )->stringify;
my $output_file_json = file( $htdocs_dir, "play", 'count.json' )->stringify;

my $template_file = file( $base_dir, "template", "play.html" )->stringify;
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
);
# 告知動画など
my @ignore = qw(
	sm7335402
	sm7337914
	sm7341325
	sm7343558
	sm7346152
	sm7473981
);

# 明らかにおかしいもの
push @ignore, qw(
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

$stash->{date} = DateTime->now( time_zone => 'Asia/Tokyo' );

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
	next if scalar( first { $v eq $_ } @jingle );
	
	# 告知動画なども飛ばそう
	next if scalar( first { $v eq $_ } @ignore );
	
	my $d = {
		video_id => $v,    # sm1234567
		vid => $video->{$v}->{id},    # 1234567
		title => scalar( $video->{$v}->{title} || q/不明/ ),
		view => $video->{$v}->{num},    # 再生数
	};
	
	# all
	push @video_all, $d;
}

# 再生回数ごとのファイル生成
for my $num( qw(20 15 10 5 3 1) ){
	my @video = grep { $_->{view} >= $num } @video_all;
	$stash->{video} = [ @video ];
	$stash->{total_video_num} = scalar @{ $stash->{video} };
	$stash->{play_count} = $num;
	
	$stash->{is_all} = 1
		if $num == 1;
	
	my $output_file = file( $htdocs_dir, "play", sprintf "over_%d.html", $num )->stringify;
	
	my $template = &create_template;
	$template->process( $template_file, $stash, $output_file, binmode => ':utf8' )
		or die $template->error;
	
	printf STDERR "%d: %d videos\n", $num, scalar @video;
}

# all tsv
{
	my $csv = Text::CSV_XS->new( { binary => 1 } );
	my @csv;
	for my $v( @video_all ){
		$csv->combine( map { Encode::encode('sjis', $_) } @{$v}{qw(view video_id title)} );
		push @csv, $csv->string;
	}

	my $fh = file( $output_file_csv )->openw or die $!;
	$fh->print( Compress::Zlib::memGzip( join "\r\n", @csv ) );
	$fh->close;
}

# all json
{
	my $list;
	for my $v( @video_all ){
		$list->{ $v->{video_id} } = $v->{view};
	}

	my $fh = file( $output_file_json )->openw or die $!;
	$fh->print( JSON::Syck::Dump( $list ) );
	$fh->close;
}

# count.db
{
	my $d = {};
	for(@video_all){
		$d->{ $_->{video_id} } = $_->{ view };
	}

	my $fh = file( $db_file )->openw or die $!;
	$fh->print( YAML::Syck::Dump( $d ) );
	$fh->close;
}

exit 0;

sub create_template {
	require Template;

	my $config = {
		INCLUDE_PATH => '.',
		ABSOLUTE => 1,
		RELATIVE => 1,
		AUTO_RESET => 1,
		ENCODING => 'utf8',    # will be passed to Encode::decode()
		PRE_CHOMP => 1,
		POST_CHOMP => 0,
		TRIM => 0,
	};

	my $tmpl_config = {
		%{ $config },
	};

	return Template->new( $tmpl_config );
}

sub usage {
	*STDOUT->printf("usage: %s\n", File::Basename::basename( $0 ));
	exit 1;
}

__END__
