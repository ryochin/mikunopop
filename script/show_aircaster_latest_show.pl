#!/usr/bin/perl --

use strict;
use warnings;
use List::Util qw(first);
use CGI;
use URI::Fetch;
use DateTime;
use Data::Dumper;
use Text::ASCIITable;

use utf8;
use Encode;

my $stash = {};

my $uri_list = [
#	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1235658251/29-400',
#	'http://jbbs.livedoor.jp/internet/2353/storage/1243754024.html',
#	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1257848535/2-',
	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1274527202/2-',
	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1304336074/2-',
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
	# <dt><a href="/bbs/read.cgi/internet/2353/1304336074/533">533</a> ：<font color="#008800"><b>たぢ</b></font>：2012/03/05(月) 04:00:02 ID:9eKKpntg<dd> ミクノポップをきかないか？ Part.6560 lv84036504 (2012/03/05 02:22-)<br>sm12791392 【ジングル】ミクノポップをきかないか？【mikuno music.】<br>sm15523227 雪歌ユフによる「ストロボハロー」Remix<br>sm14437872 【歌愛ユキ】　just killing time　【オリジナル】<br>sm13795221 【Minimal】 default is default 【唄音ウタ】<br>sm17156698 【巡音ルカ】 meisou 【オリジナル】<br>sm15587422 【GUMI】 アプシスの果て 【宇宙的オリジナル曲】<br>sm12588223 【初音ミク】クラウドチャンバー【オリジナル曲PV】<br>nm7851915 【カバーアレンジ】耳のあるロボットの唄【雪歌ユフ】<br><br>ミクノポップをきかないか？ Part.6561 lv84039545 (2012/03/05 02:55-)<br>sm12791392 【ジングル】ミクノポップをきかないか？【mikuno music.】<br>sm8833550 [初音ミク]CLEAR WALLS MUSEUM[オリジナル曲]<br>sm14838125 【初音ミク】 transpose III  【オリジナル】<br>sm16872002 【GUMI】 ヘイユー！ 【オリジナル曲】<br>sm17135592 【UTAU】TETOgroove【重音テト】<br>sm12071713 【雪歌ユフ】　hp　【オリジナル】<br>sm5883355 【初音ミクオリジナル曲】ワタシアナライザー【PV】<br>nm6916338 【雪歌ユフ】空想マインド【UTAUオリジナル曲】<br><br>ミクノポップをきかないか？ Part.6602 lv84041994 (2012/03/05 03:26-)<br>sm12791392 【ジングル】ミクノポップをきかないか？【mikuno music.】<br>sm4107374 【初音ミク】ジェイコブズ・ラダー【オリジナル】<br>sm12302838 【UTAU/デフォ子】apple cookie 2.0【オリジナル】<br>sm16836594 【巡音ルカ】 忘れてしまうしかないこと 【ガチオリジナル曲】<br>sm4159137 eKlosioN 【初音ミクオリジナル曲】<br>sm4924038 【雨降り】ストライクザワールド【ミクオリジナル】<br>sm13097309 根音ネネ／そらに歩く樹（UTAUオリジナル）<br><br>最初の２枠のpart No.をつけ間違えていました。申し訳ないです。<br>放送時Part6598/6599となっていましたが正しくは6600/6601となります。<br>こちらにて修正しておきます。 <br><br>
	
	my $part = "";
	if( $line =~ /^.+?part[\.\s]*(\d+).+?$/io ){
		$part = $1;
	}
	
	my $aircaster = "";
	if( $line =~ m{<(a href="[^"]+"|font .+?)><b>([^<>]+)</b></(a|font)>}io ){    # "
		$aircaster = $2;
		next if first { $aircaster =~ /$_/ } ( qr{ジングル}, qr{なまはい}, qr{寝落ち}, qr{枠}, qr{クロスフェード}, qr{特集}, qr{代理カキコ}, qr{補正}, qr{まいして} );
		
		$aircaster = 'きぬこもち' if $aircaster =~ /ルカ姉様/o;
		$aircaster = 'higumon' if $aircaster =~ /higumon.+/o;
		$aircaster = 'メガーネ君＠生主' if $aircaster =~ /メガーネ/o;
		$aircaster = 'メガーネ君＠生主' if $aircaster =~ /めがね/o;
		$aircaster = 'SOL' if $aircaster =~ /ＳＯＬ/o;
		$aircaster = 'SOL' if $aircaster =~ /Ｓ.Ｏ.Ｌ/o;
		$aircaster = 'SOL' if $aircaster =~ /S\.O\.L/io;
		$aircaster = 'SOL' if $aircaster =~ /sol/o;
		$aircaster = 'Mint=Rabbit' if $aircaster =~ /Mint.+/o;
		$aircaster = 'bird-m@トリィ' if $aircaster =~ /トリィ/o;
		$aircaster = 'くらんち' if $aircaster =~ /くらんち.+/o;
		$aircaster = 'シャガール' if $aircaster =~ /shaghar/io;
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
#		next if $data !~ /^\s*?[\-]*?\s*?(sm|nm)[0-9]{7,8}/o;
		next if $data !~ /(sm|nm)[0-9]{7,8}/o;
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

my $limit = DateTime->now( time_zone => 'local' )->add( days => -30 );
my $flag = 0;

my $flag_halfyear = 0;
my $limit_halfyear = DateTime->now( time_zone => 'local' )->add( days => -180 );

my $flag_oneyear = 0;
my $limit_oneyear = DateTime->now( time_zone => 'local' )->add( days => -365 );

my $table = Text::ASCIITable->new( { allowANSI => 1 } );
$table->setCols( qw(last_date aircaster) );
$table->alignCol( aircaster => 'left' );

for my $aircaster( sort { $list->{$a} <=> $list->{$b} } keys %{ $list } ){
	if( not $flag and $list->{ $aircaster }->epoch > $limit->epoch ){
		$table->addRow("----------------", "[ 1 month ]");
		$flag++;
	}
	if( not $flag_halfyear and $list->{ $aircaster }->epoch > $limit_halfyear->epoch ){
		$table->addRow("----------------", "[ 6 month ]");
		$flag_halfyear++;
	}
#	if( not $flag_oneyear and $list->{ $aircaster }->epoch > $limit_oneyear->epoch ){
#		$table->addRow("----------------", "[ 1 year ]");
#		$flag_oneyear++;
#	}
	
	$table->addRow( $list->{ $aircaster }->ymd("."), Encode::encode_utf8( $aircaster ) );
}

print $table->draw(
	[qw(+ + - +)],
	[qw(| | |)],
	[qw(+ + - )],
	[qw(| | |)],
	[qw(+ + - +)],
);

__END__
