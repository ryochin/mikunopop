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
# -t: local test mode

my $min = defined $opt->{t} ? 12 : 3;    # 少なくとも再生されている数
my $uri = 'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1235658251/29-';
my $output_file = defined $opt->{t} ? './mikunopop.html' : '/web/saihane/htdocs/mikunopop.html';

my @jingle = qw(
	sm6789292
	sm6789315
	sm6939234
	sm6981084
);

my $content = get( $uri ) or die "cannot get html!";
$content = Encode::decode( 'euc-jp', $content );

my $stash = {};
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

$stash->{video} = [];
for my $v( sort { $video->{$b}->{num} <=> $video->{$a}->{num} || $video->{$a}->{id} <=> $video->{$b}->{id} } keys %{ $video } ){
	
	next if $video->{$v}->{num} < $min;
	
	push @{ $stash->{video} }, {
		video_id => $v,
		vid => $video->{$v}->{id},
		title => scalar( $video->{$v}->{title} || q/不明/ ),
		view => $video->{$v}->{num},    # 再生数
		is_jingle => scalar( first { $v eq $_ } @jingle ),
	};
}

warn scalar @{ $stash->{video} };

# out
my $template = &create_template;
$template->process( \ do { local $/; <DATA> }, $stash, $output_file, binmode => ':utf8' )
	or die $template->error;

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

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="ja-JP" xml:lang="ja-JP" xmlns="http://www.w3.org/1999/xhtml">
<head>
<link rev="made" href="mailto:webmaster&#64;example.com" />
<link rel="icon" type="image/x-icon" href="/favicon.ico" />
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta http-equiv="Content-Language" content="ja" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<meta name="robots" content="noindex,nofollow" />
<link rel="stylesheet" type="text/css" media="screen,projection,tv,print" href="./css/colorbox.css" charset="utf-8" />
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3/jquery.min.js" type="text/javascript"></script>
<script src="./js/jquery.colorbox.js" type="text/javascript"></script>
<title>ミクノポップ再生回数</title>
<style type="text/css">
body {
	color: #eee;
	background: #000;
}
a {
	color: #eee;
	text-decoration: none;
}
img {
	border: 0;
}
table {
	margin: 4px;
}
p {
	font-size: 92%;
}
span.video_id {
	font-size: 92%;
	font-weight: bold;
}
span.title {
	font-size: 107%;
}
</style>
<script type="text/javascript">
<!--// <![CDATA[

$(document).ready( function () {
	$('a.image').each( function () {
		var id = $(this).attr('href').replace(/^.+\/((sm|nm).+)$/, "$1");
		var uri = 'http://ext.nicovideo.jp/thumb/' + id;
		
		// set
		$(this).colorbox( {
			href: uri,
			iframe: 1,
			fixedWidth: 340,
			fixedHeight: 200,
			transitionSpeed: 200
		} );
	} );
} );

// ]]> -->
</script>
</head>
<body>

<div id="container">

	<h1>ミクノポップ再生回数 @ [% date.strftime("%Y年%m月%d日 %H時") %] 現在</h1>
	
	<p>
		<a href="http://ch.nicovideo.jp/community/co13879" target="_blank">ミクノポップ</a>の過去放送ログから、再生回数が３回以上の曲を、再生回数が多い順（同数なら古い順）に並べています。
	</p>
	
	<p>
		プログラムで自動生成しているので、多少おかしな点があるかも。
	</p>
	
	<p>
		サムネクリックで詳細を表示、曲名クリックで動画を開くよ。IE だと詳細が閉じないけど、まぁいいか・・。
	</p>
	
	<table summary="list">
[% FOR v = video %]
		<tr>
			<td rowspan="2" align="center">
				[% v.view | html %] 回
				[% IF v.is_jingle %]
					<br />
					（ジングル）
				[% END %]
			</td>
			<td rowspan="2" valign="top">
				<a href="http://www.nicovideo.jp/watch/[% v.video_id | html %]" target="_blank" class="image">
					<img alt="[% v.title | html %]" src="http://tn-skr1.smilevideo.jp/smile?i=[% v.vid | html %]" 
						width="130" height="100" class="video-thumbnail" />
				</a>
			</td>
			<td rowspan="2">
				&nbsp;
			</td>
			<td valign="top">
				<a href="http://www.nicovideo.jp/watch/[% v.video_id | html %]" target="_blank" title="ニコニコ動画で見る">
					<span class="title">[% v.title | html %]</span>
				</a>
				&nbsp;
				<a href="http://dic.nicovideo.jp/v/[% v.video_id | html %]" target="_blank">
					<img src="http://res.nicovideo.jp/img/common/icon/dic_on.gif" />
				</a>
				&nbsp;
				<img src="http://b.hatena.ne.jp/entry/image/small/http://www.nicovideo.jp/watch/[% v.video_id | html %]" alt="ブックマークユーザ数" valign="bottom" />
			</td>
		</tr>
		<tr>
			<td valign="top">
				<span class="video_id">
					[% v.video_id | html %]
				</span>
			</td>
		</tr>
[% END %]
	</table>
	
</div>

</body>
</html>

