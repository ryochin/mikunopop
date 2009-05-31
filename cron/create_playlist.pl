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

use utf8;
use Encode;

# getopt
Getopt::Std::getopts 't' => my $opt = {};

my $stash = {};

my $min_short = 5;
my $min_full = 3;
my $min_all = 1;

my $base_dir = '/web/mikunopop/';
my $htdocs_dir = file( $base_dir, "htdocs" );

my $output_file_short = file( $htdocs_dir, "play", 'index.html' )->stringify;
my $output_file_full = file( $htdocs_dir, "play", 'full.html' )->stringify;
my $output_file_all = file( $htdocs_dir, "play", 'all.html' )->stringify;
my $output_file_csv = file( $htdocs_dir, "play", 'all.csv.gz' )->stringify;

my $template_file = file( $base_dir, "template", "play.html" )->stringify;
my $uri_list = [
	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1235658251/29-400',
	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1243754024/2-',
];

my @jingle = qw(
	sm6789292
	sm6789315
	sm6939234
	sm6981084
	sm7007629
	sm7033805
	sm7075450
);

my $content;
for my $uri( @{ $uri_list } ){
	if( my $c = get( $uri ) ){
		$content .= Encode::decode( 'euc-jp', $c );
	}
}

$stash->{date} = DateTime->now( time_zone => 'Asia/Tokyo' );

my $video = {};
for my $line( split /\n/o, $content ){
	next if $line !~ /<dt>/o;
	chomp $line;
#	$line = Encode::decode_utf8( $line );
	$line = CGI::unescapeHTML( $line );
	
	my $seen = {};
	for my $data( split m{<br>}, $line ){
		next if $data !~ /^(sm|nm)[0-9]{7,8}/o;
		
		my ($n, $title) = unpack "A9 A*", $data;
		$title = Encode::decode_utf8( $title );
		$title =~ s/^[　\s\t]+//o;
		
		# duplicate check
		next if defined $seen->{ $n };
		$seen->{ $n } = 1;
		
		( my $id = $n ) =~ s/^(sm|nm)+//o;
		
		$video->{ $n }->{num}++;
		$video->{ $n }->{id} ||= $id;
		
		# title
		if( defined $title and length( $title ) > 8 ){
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

my @video_short;
my @video_full;
my @video_all;
for my $v( sort { $video->{$b}->{num} <=> $video->{$a}->{num} || $video->{$a}->{id} <=> $video->{$b}->{id} } keys %{ $video } ){
	
	# ジングルは飛ばそう
	next if scalar( first { $v eq $_ } @jingle );
	
	my $d = {
		video_id => $v,    # sm1234567
		vid => $video->{$v}->{id},    # 1234567
		title => scalar( $video->{$v}->{title} || q/不明/ ),
		view => $video->{$v}->{num},    # 再生数
	};
	
	# short
	push @video_short, $d
		if $video->{$v}->{num} >= $min_short;
	
	# full
	push @video_full, $d
		if $video->{$v}->{num} >= $min_full;
	
	# all
	push @video_all, $d;
}

## short
{
	$stash->{video} = [ @video_short ];
	$stash->{total_video_num} = scalar @{ $stash->{video} };
	$stash->{is_full} = 0;
	$stash->{play_count} = $min_short;
	
	my $template = &create_template;
	$template->process( $template_file, $stash, $output_file_short, binmode => ':utf8' )
		or die $template->error;
	
	printf STDERR "%d: %d videos\n", $min_short, scalar @video_short;
}

## full
{
	$stash->{video} = [ @video_full ];
	$stash->{total_video_num} = scalar @{ $stash->{video} };
	$stash->{is_full} = 1;
	$stash->{play_count} = $min_full;

	my $template = &create_template;
	$template->process( $template_file, $stash, $output_file_full, binmode => ':utf8' )
		or die $template->error;
	
	printf STDERR "%d: %d videos\n", $min_full, scalar @video_full;
}

## all
{
	$stash->{video} = [ @video_all ];
	$stash->{total_video_num} = scalar @{ $stash->{video} };
	$stash->{is_all} = 1;
	$stash->{play_count} = $min_all;

	my $template = &create_template;
	$template->process( $template_file, $stash, $output_file_all, binmode => ':utf8' )
		or die $template->error;
	
	printf STDERR "%d: %d videos\n", $min_all, scalar @video_all;
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
	*STDOUT->printf("usage: %s <html file>\n", File::Basename::basename( $0 ));
	exit 1;
}

__END__
