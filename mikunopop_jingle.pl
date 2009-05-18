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

my $base_dir = defined $opt->{t} ? '.' : '/web/saihane/htdocs/';
my $output_file = file( $base_dir, 'mikunopop_jingle.html' )->stringify;

my @jingle = (
	{
		video_id => 'sm6789292',
		vid => '6789292',
		title => '【初音ミク】近未来ラジオ【ジングル用】',
		author => 'ぎんさん',
		desc => 'ジングルその１。すべてはここから始まった！',
	},
	{
		video_id => 'sm6789315',
		vid => '6789315',
		title => '【初音ミク】近未来ラジオ【ジングル用】',
		author => 'ぎんさん',
		desc => 'ジングルその２。',
	},
	{
		video_id => 'sm6939234',
		vid => '6939234',
		title => '【ジングル】ミクノポップクエスト【sunlight loops】',
		author => '？さん',
		desc => '勇者あすたあの冒険編。',
	},
	{
		video_id => 'sm6981084',
		vid => '6981084',
		title => '【ジングル】ミクノポップをきかないか？ジングル【近未来ラジオver】',
		author => '？さん',
		desc => '',
	},
	{
		video_id => 'sm7007629',
		vid => '7007629',
		title => '【ジングル】音楽が降りてくる【lysosome】',
		author => '？さん',
		desc => 'A*ster「びにゅＰはおれの嫁」kotac「おれの嫁」higumon「おれの」saihane「俺」io「・・・」',
	},
	{
		video_id => 'sm7033805',
		vid => '7033805',
		title => '【ジングル】ミクノポップをきかないか？【Freestyle ver】',
		author => 'aoid さん',
		desc => '',
	},
	{
		video_id => 'sm7075450',
		vid => '7075450',
		title => '【ジングル】円の中の世界【EN】',
		author => '? さん',
		desc => '',
	},
);

my $n = 0;
for my $jingle( @jingle ){
	$n++;
	unshift @{ $stash->{video} }, {
		n => $n,
		%{ $jingle },
	};
}

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
<title>「ミクノポップをきかないか？」ジングル集</title>
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
} );

// ]]> -->
</script>
</head>
<body>

<div id="container">

	<h1>「ミクノポップをきかないか？」ジングル集</h1>
	
	<p>
		ジングル集です。まだでっち上げ状態なので、情報ください。<br />
		情報ないなら適当に書いちゃうよ！（さいはね）
	</p>

	<br />
	
	<table summary="list">
		<tr class="table-desc">
			<td align="center">発表順</td>
			<td align="center">サムネイル</td>
			<td align="center" width="32">&nbsp;</td>
			<td align="left">　ジングルの説明</td>
		</tr>
[% FOR v = video %]
		<tr>
			<td rowspan="2" align="center">
				[% v.n | html %]
			</td>
			<td rowspan="2" valign="top">
				<a href="http://www.nicovideo.jp/watch/[% v.video_id | html %]" target="_blank" class="image">
					<img alt="[% v.title | html %]" src="http://tn-skr4.smilevideo.jp/smile?i=[% v.vid | html %]" 
						class="video_w96 video-thumbnail" />
				</a>
			</td>
			<td rowspan="2">
				&nbsp;
			</td>
			<td valign="top">
				<a href="http://www.nicovideo.jp/watch/[% v.video_id | html %]" target="_blank" title="ニコニコ動画で見る">
					<span class="title">[% v.title | html %]</span>
				</a>
			</td>
		</tr>
		<tr>
			<td valign="top">
				<span class="video_id">
					[% v.video_id | html %]
				</span>
				&nbsp; 
				<span class="author">
					[% v.author | html %]作。
				</span>
				&nbsp; 
				<span class="desc">
					[% v.desc | html %]
				</span>
			</td>
		</tr>
[% END %]
	</table>
</div>

</body>
</html>

