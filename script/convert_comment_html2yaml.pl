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
if( $content =~ m{<h3 class="title".*?><strong>([^<>]+?)</strong>}io ){
	$db->{title} = CGI::unescapeHTML( $1 );
	if( $db->{title} =~ m{(\d+)}io ){
		$db->{part} = $1;
	}
}

# admin
if( $content =~ m{<h2><strong><a href="http://www.nicovideo.jp/my" id="myname">([^<>]+?)</a>}io ){
	$db->{aircaster} = CGI::unescapeHTML( $1 );
}
elsif( $content =~ m{<a href="http://www.nicovideo.jp/my" id="myname">([^<>]+?)</a>\s*さん}io ){
	$db->{aircaster} = CGI::unescapeHTML( $1 );
}
elsif( $content =~ m{<A id=myname href="http://www.nicovideo.jp/my">([^<>]+?)</A> }io ){
	$db->{aircaster} = CGI::unescapeHTML( $1 );
}
elsif( $content =~ m{<A id=myname[\n\s]+?href="http://www.nicovideo.jp/my">([^<>]+?)</A> }iosm ){
	$db->{aircaster} = CGI::unescapeHTML( $1 );
}

my @content;
my $seen = {};
my $cnt = 0;
for my $chunk( split m{</tr>}io, $content ){
	$chunk =~ s/\r//go;
	$chunk =~ s{ \n\s+(width)}{ $1}gosmi;
	
	$chunk =~ s{[\s\n\t]*<DIV .*?>([^<>]+)</DIV>}{$1}gsmi;
	
	$chunk =~ s{<tr[^<>]*class="?(odd|even)"?.*?>.+?<td nowrap[^<>]*>([\d\/\s\:]+?)</td>.+?<td.+?(style="color:\s?\#([\w\d]+)")*( width="100%")*>([^<>]*?)</td>.+?<td>(\d+)</td>}{
		my $d = {
			date => $2,
			no => $7,
			is_odd => scalar( ++$cnt % 2 ),
		};
		my $content = $d->{comment} = $6;    # すでにエスケープされているんだから、そのまま入れてそのまま表示する方針で。
		if( $content eq '' ){
			# bug?
			$d->{is_empty} = 1;
		}
		
		if( my $color = $4 ){
			if( $color eq 'aaa' ){
				$d->{is_hidden} = 1;
			}
			elsif( $color eq 'ff4d00' ){
				$d->{is_admin} = 1;
			}
			else{
				$d->{is_admin} = 1;
			}
		}
		
		# 改行を削る
		if( defined $d->{is_admin} and $d->{is_admin} ){
			$d->{comment} =~ s{\n\s+}{}gso;
		}
		
		# duplicate check
		# -> kawa さんの主コメント（曲名とか）の重複を削る
		my $content_admin = substr $content, 0, 30;
		if( ( defined $d->{is_admin} and $d->{is_admin} ) and length $content_admin > 20 and defined $seen->{ $content_admin } ){
			;
		}
		else{
			$seen->{ $content_admin } = 1;
			
			push @content, $d;
		}
	}egios;
}

# sort
@content = sort { $a->{no} <=> $b->{no} } @content;
$db->{content} = [ @content ];

# 放送時間を算出する
my $start = main->parse_datetime( $content[0]->{date} );
my $end = main->parse_datetime( $content[-1]->{date} );
my $min = int( ( $end->epoch - $start->epoch ) / 60 );
$db->{time} = $min;
$db->{frame} = int( ( ( $min - 10 ) / 30 ) + 1 );

# 予約の時は３分前からコメできるからずれちゃうので直す
if( $start->minute > 50 ){
	$start->add( minutes => 10 )->set( minute => 0 );
}

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
	return DateTime->from_object( object => $dt );
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

					<TR class="even" style="background-color:#DDD">
				<TD nowrap="">2009/06/05 00:29:29</TD>
								<TD width="100&percnt;">長時間乙でした～</TD>
								<TD>1884</TD>
			</TR>
					<TR class="odd">
				<TD nowrap="">2009/06/05 00:29:34</TD>
								<TD width="100&percnt;" style="color:#ff4d00">では、みんさんありがとうございました～</TD> 
								<TD>1885</TD>
			</TR>
