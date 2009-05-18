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

my $stash = {};

my $min_short = $stash->{min_short} = 5;
my $min_full = 3;
my $base_dir = defined $opt->{t} ? '.' : '/web/saihane/htdocs/';
my $output_file_short = file( $base_dir, 'mikunopop.html' )->stringify;
my $output_file_full = file( $base_dir, 'mikunopop_full.html' )->stringify;
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

my $tt_content = \ do { local $/; <DATA> };

## short
{
	$stash->{video} = [ @video_short ];
	$stash->{total_video_num} = scalar @{ $stash->{video} };
	$stash->{is_full} = 0;
	
	my $template = &create_template;
	$template->process( $tt_content, $stash, $output_file_short, binmode => ':utf8' )
		or die $template->error;
}

## full
{
	$stash->{video} = [ @video_full ];
	$stash->{total_video_num} = scalar @{ $stash->{video} };
	$stash->{is_full} = 1;

	my $template = &create_template;
	$template->process( $tt_content, $stash, $output_file_full, binmode => ':utf8' )
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
<title>「ミクノポップをきかないか？」再生回数</title>
<style type="text/css">
body {
	color: #eee;
	background: #000;
}
a {
	color: #eef;
	text-decoration: none;
}
img {
	border: 0;
}
img.video_w130 {
	width: 130px; 
	height: 100px;
}
img.video_w96 {
	width: 96px; 
	height: 72px;
}
table {
	margin: 4px;
}
h1 {
	font-size: 122%;
	font-weight: bold;
}
p {
	margin: 2px 2em;
	font-size: 92%;
	line-height: 150%;
}
tr.table-desc {
	color: #999;
	font-size: 85%;
}
span#show-desc {
	color: #ccccff;
}
span.video_id {
	color: #ffcccc;
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
	
	// show-desc
	$('#show-desc').click( function () {
		$('#desc').show();
		return false;
	} );
} );

// ]]> -->
</script>
</head>
<body>

<div id="container">

	<h1>「ミクノポップをきかないか？」再生回数</h1>
	
	<p>
		[% date.strftime("%Y年%m月%d日 %H時") %] 現在の記録です。[% total_video_num | html %] 件の動画をリストしています。<br />
		[% IF is_full %]
			[<a href="./mikunopop.html">簡易版に戻る</a>]
		[% ELSE %]
			<span id="show-desc">[クリックで詳しい説明を表示]</span><br />
			[<a href="./mikunopop_full.html">全部見る（すごく重いです）</a>]
		[% END %]
	</p>

	<p id="desc" style="display: none">
		<a href="http://ch.nicovideo.jp/community/co13879" target="_blank">ミクノポップ</a>過去放送ログから、再生回数が [% min_short %] 回以上の曲を、再生回数が多い順（同数なら古い順）に並べています。<br />
		日に数回更新。プログラムで自動生成しているので、多少おかしな点があるかも（by <a href="http://www.nicovideo.jp/user/96593" target="_blank">さいはね</a>）。<br />
		サムネクリックで詳細を表示、曲名クリックで動画を開くよ。IE だと詳細が閉じないけど、まぁいいか・・。<br />
		<br />
		ジングル動画は除くことにしました。(05/10)<br />
		nm63***** 以降の曲には「流れない曲？」と注を出すことにしました。(05/10)<br />
		nm が流れるようになったので注を出さないようにしました。(05/14)<br />
		そろそろ数が多くなってきたので、回数が少ないものは別ページに分けました。(05/16)<br />
		サムネ画像も縮小してみました。大きいほうがいい？(05/16)<br />
	</p>
	
	<br />
	
	<table summary="list">
		<tr class="table-desc">
			<td align="center">再生された回数</td>
			<td align="center">サムネイル</td>
			<td align="center" width="32">&nbsp;</td>
			<td align="left">　動画の説明</td>
		</tr>
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
[% IF is_full %]
					<img alt="[% v.title | html %]" src="http://tn-skr4.smilevideo.jp/smile?i=[% v.vid | html %]" 
						class="video_w96 video-thumbnail" />
[% ELSE %]
					<img alt="[% v.title | html %]" src="http://tn-skr4.smilevideo.jp/smile?i=[% v.vid | html %]" 
						class="video_w96 video-thumbnail" />
[% END %]
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
				<a href="http://nicosound.anyap.info/sound/[% v.video_id | html %]" target="_blank" title="にこ☆さうんど＃で見る">
					<img src="/img/music.gif" />
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
	
	<p>
		[% IF is_full %]
			[<a href="./mikunopop.html">簡易版に戻る</a>]
		[% ELSE %]
			[<a href="./mikunopop_full.html">全部見る（すごく重いです）</a>]
		[% END %]
	</p>
</div>

</body>
</html>

