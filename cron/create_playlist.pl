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

use utf8;
use Encode;

# getopt
Getopt::Std::getopts 't' => my $opt = {};

my $stash = {};

my $min_short = $stash->{min_short} = 5;
my $min_full = 3;

my $base_dir = '/web/mikunopop/';
my $htdocs_dir = file( $base_dir, "htdocs" );

my $output_file_short = file( $htdocs_dir, "play", 'index.html' )->stringify;
my $output_file_full = file( $htdocs_dir, "play", 'full.html' )->stringify;
my $template_file = file( $base_dir, "template", "play.html" )->stringify;
my $uri_list = [
	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1235658251/29-',
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
	
	for my $data( split m{<br>}, $line ){
		next if $data !~ /^(sm|nm)[0-9]{7,8}/o;
		
		my ($n, $title) = unpack "A9 A*", $data;
		$title = Encode::decode_utf8( $title );
		$title =~ s/^[　\s\t]+//o;
		
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

my @video_short;    # mikunopop.html
my @video_full;    # mikunopop_full.html
for my $v( sort { $video->{$b}->{num} <=> $video->{$a}->{num} || $video->{$a}->{id} <=> $video->{$b}->{id} } keys %{ $video } ){
	
	# ジングルは飛ばそう
	next if scalar( first { $v eq $_ } @jingle );
	
	my $d = {
		video_id => $v,
		vid => $video->{$v}->{id},
		title => scalar( $video->{$v}->{title} || q/不明/ ),
		view => $video->{$v}->{num},    # 再生数
#		is_jingle => scalar( first { $v eq $_ } @jingle ),
	};
	
	# short
	push @video_short, $d
		if $video->{$v}->{num} >= $min_short;
	
	# full
	push @video_full, $d
		if $video->{$v}->{num} >= $min_full;
}

## short
{
	$stash->{video} = [ @video_short ];
	$stash->{total_video_num} = scalar @{ $stash->{video} };
	$stash->{is_full} = 0;
	
	my $template = &create_template;
	$template->process( $template_file, $stash, $output_file_short, binmode => ':utf8' )
		or die $template->error;
}

## full
{
	$stash->{video} = [ @video_full ];
	$stash->{total_video_num} = scalar @{ $stash->{video} };
	$stash->{is_full} = 1;

	my $template = &create_template;
	$template->process( $template_file, $stash, $output_file_full, binmode => ':utf8' )
		or die $template->error;
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
