#!/usr/bin/perl --

use strict;
use warnings;
use List::Util qw(first);
use CGI;
use URI::Fetch;
use DateTime;
use Data::Dumper;

use utf8;
use Encode;

my $stash = {};

my $uri_list = [
#	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1235658251/29-400',
#	'http://jbbs.livedoor.jp/internet/2353/storage/1243754024.html',
#	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1257848535/2-',
	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1274527202/2-',
];

my $content;
for my $uri( @{ $uri_list } ){
	my $res = URI::Fetch->fetch( $uri )
		or die URI::Fetch->errstr;
	
	if( my $c = $res->content ){
		printf STDERR "uri: %s: ok.\n", $uri;
		$content .= eval { Encode::decode( 'euc-jp', $c ) } || $c;
	}
	else{
		printf STDERR "uri: %s: failed.\n", $uri;
	}
	sleep 1;
}

my $list = {};
for my $line( split /\n/o, $content ){
	next if $line !~ /<dt>/o;
	chomp $line;
	$line = CGI::unescapeHTML( $line );
	
	# <dt><a href="/bbs/read.cgi/internet/2353/1235658251/223">223</a> ：<a href="mailto:sage"><b>saihane</b></a>：2009/05/04(月) 12:15:16 ID:???<dd> Part.617 lv862991<br>nm6376344　【初音ミク】ふたり(ミク/DS-10たん)のもじぴったん(Ver.1.0-Release)【DS-10】<br>sm6357126　サイコキャンディー【初音ミクオリジナル】<br>sm3614847　【初音ミク】ヒカリトミライ【オリジナル】<br>sm6071158　【初音ミク】 star dust　【オリジナル】<br>sm6298794　【初音ミク】YOUTHFUL DAYS' GRAFFITI【オリジナル】<br>nm6302960　初音ミク「doll against you」【オリジナル】<br>nm6347684　【初音ミク】　water　【オリジナル】<br><br>Part.618 lv863285<br>sm6309541　Spring ☆ time feat.初音ミク【ミクオリジナル曲】<br>sm6345838　【初音ミク】 install 【オリジナル曲】<br>sm6863149　【初音ミク】　恋のサマードライブ　【オリジナル曲】<br>sm4675652　【初音ミク】discord【オリジナル】<br>sm6306989　【初音ミク】 clear veil 【オリジナル】<br>sm6321280　【初音ミク オリジナル】 Bitchy Driver :PV 【ドSミク】 <br><br>
	
	my $part = "";
	if( $line =~ /^.+?part[\.\s]*(\d+).+?$/io ){
		$part = $1;
	}
	
	my $aircaster = "";
	if( $line =~ m{<a href="[^"]+"><b>([^<>]+)</b></a>}io ){    # "
		$aircaster = $1;
		next if first { $aircaster =~ /$_/ } ( qr{ジングル}, qr{なまはい}, qr{寝落ち}, qr{枠}, qr{クロスフェード}, qr{特集}, qr{代理カキコ} );
		
		$aircaster = 'きぬこもち' if $aircaster =~ /ルカ姉様/o;
		$aircaster = 'higumon' if $aircaster =~ /higumon.+/o;
		$aircaster = 'メガーネ君＠生主' if $aircaster =~ /メガーネ/o;
		$aircaster = 'メガーネ君＠生主' if $aircaster =~ /めがね/o;
		$aircaster = 'SOL' if $aircaster =~ /ＳＯＬ/o;
		$aircaster = 'SOL' if $aircaster =~ /Ｓ.Ｏ.Ｌ/o;
		$aircaster = 'Mint=Rabbit' if $aircaster =~ /Mint.+/o;
		$aircaster = 'bird-m@トリィ' if $aircaster =~ /トリィ/o;
		$aircaster = 'くらんち' if $aircaster =~ /くらんち.+/o;
	}
	else{
		next;
	}
	
	# date
	my $date = "";
	if( $line =~ m{(\d{4}/\d{2}/\d{2})} ){
		my ($year, $month, $day) = grep { int $_ } split '/', $1;
		$date = DateTime->new( year => $year, month => $month, day => $day );
	}
	
	my $cnt = 0;
	for my $data( split m{<br>}, $line ){
		next if $data !~ /^\s*?[\-]*?\s*?(sm|nm)[0-9]{7,8}/o;
		$cnt++;
	}
	
	# notice: 以下の基準はカンペキではない。
	
	# おそらく放送じゃない
	if( $part eq '' and $cnt == 0 ){
		next;
	}
	
	# パート番号があるのに曲が１つもないのは放送と関係ない
	if( $part ne '' and $cnt == 0 ){
		next;
	}
	
	# パート番号があっても曲が２つくらいなのは怪しい
	if( $part ne '' and $cnt <= 2 ){
		next;
	}
	
	# パート番号がなくても曲が３つ以上あれば放送だろう
	if( $part eq '' and $cnt <= 2 ){
		next;
	}
	
	$list->{ $aircaster } = $date;
}

for my $aircaster( sort { $list->{$a} <=> $list->{$b} } keys %{ $list } ){
	printf "%s: %s\n", Encode::encode_utf8( $aircaster ), $list->{ $aircaster }->ymd(".");
}

__END__


