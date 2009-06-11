#!/usr/bin/perl --

use strict;
use warnings;
use Getopt::Std;
use Path::Class qw(file dir);
use IO::Handle;
use File::Basename;
use List::Util  qw(first);
use Data::Dumper;
use CGI;
use YAML::Syck;
local $YAML::Syck::ImplicitUnicode = 1;
use DateTime;
use DateTime::TimeZone;
use DateTime::Format::MySQL;

use utf8;
#use bytes ();
use Encode;

binmode STDOUT, ':utf8';

# getopt
Getopt::Std::getopts 'v' => my $opt = {};
# -v: verbose

my @file = @ARGV or &usage;

my $content;
for my $file( @file ){
	my $fh = file( $file )->openr or die $!;
	$content .= Encode::decode_utf8( do { local $/; <$fh> } );
	$fh->close;
}

my $db = {};

# title
if( $content =~ m{<h3 class="title"><strong>([^<>]+?)</strong>}o ){
	$db->{title} = CGI::unescapeHTML( $1 );
	if( $db->{title} =~ m{(\d+)}io ){
		$db->{part} = $1;
	}
}

# admin
if( $content =~ m{<h2><strong><a href="http://www.nicovideo.jp/my" id="myname">([^<>]+?)</a>}o ){
	$db->{aircaster} = CGI::unescapeHTML( $1 );
}

my @content;
my $cnt = 0;
$content =~ s{<tr class="(odd|even)".*?>.+?<td nowrap>([\d\/\s\:]+?)</td>.+?<td.+?( style="color:\#([\w\d]+)")*>([^<>]+?)</td>.+?<td>(\d+)</td>}{
	my $is_admin = 0;
	my $is_hidden = 0;
	if( my $color = $4 ){
		if( $color eq 'aaa' ){
			$is_hidden = 1;
		}
		else{
			$is_admin = 1;
		}
	}
	push @content, {
		date => $2,
		is_admin => $is_admin,
		is_hidden => $is_hidden,
		comment => CGI::unescapeHTML( $5 ),
		no => $6,
		is_odd => scalar( ++$cnt % 2 ),
	};
}egos;

# sort
@content = sort { $a->{no} <=> $b->{no} } @content;
$db->{content} = [ @content ];

# 放送時間を算出する
my $start = main->parse_datetime( $content[0]->{date} );
my $end = main->parse_datetime( $content[-1]->{date} );
my $min = int( ( $end->epoch - $start->epoch ) / 60 );
$db->{time} = $min;
$db->{frame} = int( ( ( $min - 10 ) / 30 ) + 1 );

# 開始時刻をセットする
$db->{start} = $start->epoch;

# output
print YAML::Syck::Dump( $db ), "\n";

exit 0;

sub parse_datetime {
	my $class = shift;
	my $str = shift or return;
	
	$str =~ s{/}{-}go;
	
	my $dt = DateTime::Format::MySQL->parse_datetime( $str );    # ->isa: DateTime
	$dt->set_time_zone("local");
	return DateTime->from_object( object => $dt );    # ->isa: Fumi2::Date
}

sub usage {
	*STDOUT->printf("usage: %s <html file>, [<html file>] ...\n", File::Basename::basename( $0 ));
	exit 1;
}

__END__

					<tr class="odd">
				<td nowrap>2009/06/10 18:16:43</td>
								<td  width="100%" style="color:#ff4d00">■【初音ミク】[Continue]-2面【オリジナル】 ■P名?</td> 
								<td>2</td>
			</tr>
