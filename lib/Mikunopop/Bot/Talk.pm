package Mikunopop::Bot::Talk;

use strict;
use warnings;
use List::Util qw(first shuffle);
use DateTime;

use utf8;
use Encode;

my $tz = DateTime::TimeZone->new( name => 'Asia/Tokyo' );

my @reply_random = (
	q{誰か私を呼んだ？　いま忙しいからあとでね！＞%s},
	q{なによ、気安く話しかけないでよね！＞%s},
#	q{わたしの名前はミクノちゃん、でほんとにいいのかしら。},
#	q{♪　㍍⊃、溶・け・て・しっまっい〜そぉ〜　♪},
	q{さ、つぎ主やるのはだれなの？},
	q{そろそろ放送が聴きたいわね、次は%sが主やるのよ。},
	q{あらあらそんなこと言って、わたしに踏まれたいのかしら？＞%s},
	q{あらあらウフフ。＞%s},
#	q{まったく、またジャガボンゴなの？},
	q{( ﾟ∀ﾟ)o彡ﾟ%s！%s！},
	q{・・・・。},
	q{・・・・？},
	q{今すぐアイスを買ってきなさい！　姫はダッツをご所望よ！＞%s},
#	q{そうだわ、NoNoWireを爆破してらっしゃい！＞%s},
	q{なんとなくnocしたい、そんな夜もあるわよね。わかるわ・・・。},
	q{乙ですぅぅぅ！},
#	q{園長カードオープン！　「６時間延長トラップ」発動！},
#	q{「踏まれ隊」だなんて、ミクノは変態ばっかりね！},
	q{ん？},
#	q{そういえば、「ニコ生でいちばんオサレ」だなんて、ちょっと言い過ぎよね。},
#	q{メルトはもう飽きたわ。そもそもミクノ分が無いじゃない。},
	q{そろそろ私が主デビューしようかしら。},
	q{え、なに？　よく聞こえなかったわ。＞%s},
#	q{ミク廃連合もなにかテーマ曲が欲しいわね。},
	q{ん〜、それもそうね。},
	q{ん〜、よくわからないわ。},
	q{あら、そ。},
	q{ふわ〜ぁ・・},
	q{zzZ...},
	q{はぅ＞＜},
	q{__o-^L   __o-^L   __o-^L},
);

sub _talk {
	my $self = shift;
	my $args = shift or return;

	my $who = $self->convert_aircaster( $args->{who} );
	$who =~ s/_+$//o;

	if( $args->{body} =~ /(ねた|ネタ|話題|情報)(が|を|は|、)*((下|くだ)さ|ちょうだ|お?くれ|(欲|ほ)し|よこ(し|せ)|(な|無)い)/o ){
		# ネタ
		return $self->_talk_neta( $args );
	}
	elsif( $args->{body} =~ /(ありがと|アリガト)/o ){
		# ありがと
		my @reply = (
			q{どういたしまして♪＞%s},
			q{お、お礼を言われるほどのことじゃ・・///},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(ただいま|今北|今来た)/o ){
		# ただいま
		my @reply = (
			q{おかえりなさいませ、%s様♪},
			q{あら、おかえり。＞%s},
			q{遅かったわね、まさか別の生聴いてたんじゃないでしょうね？＞%s},
			q{いらっしゃいぃぃぃ！},
			q{き、来てくれてありがと・・なんて言うわけないでしょっ///＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(おはよ(う|ー|〜)|オハヨ(ウ|ー|〜)|お早う)/o ){
		# おはよう
		my @reply = (
			q{お、おはよう・・///＞%s},
			q{おはよう%sさん、よく眠れたかしら？},
			q{あらおはよう%sさん、ご機嫌はいかがかしら。},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(こんにち(わ|は)|コンニチ(ワ|ハ)|ちわ(ー|〜))/o ){
		# こんにちわ
		my @reply = (
			q{い、いらっしゃい・・///＞%s},
			q{こんにちわ%sさん、ご機嫌いかが？},
			q{き、来てくれてありがと・・なんて言うわけないでしょっ///＞%s},
			q{遅刻ね、駆けつけ２枠よ＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /((こんばん|今晩)(わ|は)|コンバン(ワ|ハ)|お晩で|ばわ(ー|〜|です))/o ){
		# こんばんわ
		my @reply = (
			q{い、いらっしゃい・・///＞%s},
			q{こんばんわ、%sさん♪},
			q{き、来てくれてありがと・・なんて言うわけないでしょっ///＞%s},
			q{遅刻ね、駆けつけ２枠よ＞%s},
			q{も、もっと早く来なさいよ・・///＞%s},
			q{あらこんばんわ%sさん。},
			q{あらこんばんわ%sさん、ご機嫌はいかがかしら。},
			q{こんばんわ%sさん、よい晩ね。},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(おやす(み|〜)|お休み|オヤスミ|ﾉｼ|ノシ)/o ){
		# おやすみ
		my @reply = (
			q{え、もう寝ちゃうの・・？///＞%s},
			q{おやすみ〜＞%s},
			q{おやすみ〜ん},
			q{おやすぅぅぅ＞%s},
			q{グッナイ☆＞%s},
			q{またねー＞%s},
#			q{寝てもいいなんて許可してないわ！＞%s},
#			q{あと１枠だけやってから寝なさい！＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(偉|えら)い/o ){
		# えらい
		my @reply = (
			q{そう、もっともっとほめなさい！＞%s},
			q{私が偉い？　そんなの当たり前田のクラッカーだわ。＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(凄|すご)い/o ){
		# すごい
		my @reply = (
			q{ま、まあこれくらい当然だわ！},
			q{そう、もっともっとほめなさい！＞%s},
			q{すごい？　まぁね、わたしのマスターがすごいから/// ＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(おねむ|眠い|ねむい)/o ){
		# 眠い
		my @reply = (
			q{zzZZ.. っと、寝落ちするところだったわ。},
			q{わたし、まだまだ眠くなんてないわよ＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(ぱんちゅ|ぱんつ|パンツ)/o ){
		# ぱんつ
		my @reply = (
			q{みんなの前でそんな恥ずかしいこと言わないで/// ＞%s},
			q{・・この変態！＞＜},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(好|す)き(なの.*)*(\?|？)/o ){
		# 好き
		my @reply = (
			q{まあまあ、ね。＞%s},
			q{そうでもないわね＞%s},
			q{そうね、わりと好き・・かもね。},
			q{大好き・・なんて言うわけないでしょ///＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(いい|イイ|良い)(こ|子)/o ){
		# 良い子
		my @reply = (
			q{えへへ・・///},
			q{そ、そう？　ありがと。＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(ほ|褒)めて/o ){
		# ほめて
		my @reply = (
			q{よ〜しよしよし＾＾＞%s},
			q{えらいえら〜い・・って、%sは私をほめてくれないの＞＜},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(慰|なぐさ)めて/o ){
		# 慰めて
		my @reply = (
			q{イヤよ！＞%s},
			q{慰めてほしいのはこっち・・オホン、うんまあ、つ、つらかったわね・・＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /遅い/o ){
		# 遅い
		my @reply = (
			q{ご、ゴメンナサイ・・＞%s},
			q{ふんっ、少しくらい遅くても地球はちゃんと回るわ！＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /言って((まし)*た|ます|真下)/o ){
		# 言ってました
		my @reply = (
			q{・・・。},
			q{言 っ て ま せ ん},
			q{そうだったかしら・・？　記憶があいまいだわ。＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /はぐらかされ/o ){
		# はぐらかされた
		my @reply = (
			q{そんなことないわ、私はいつだって真摯よ。},
			q{そうだったかしら・・？　記憶があいまいだわ。＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /出番(だ|よ|が)/o ){
		# 出番よ
		my @reply = (
			q{あら、枠取ってくるからちょっと待っててちょうだい。},
			q{私はいま忙しいの。代わりにやっといて。＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /だよね？/o ){
		# だよね？
		my @reply = (
			q{そうかしら。},
			q{知らないわ。＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(いじ|弄)(ろう|って|りたい)/o ){
		# いじろう
		my @reply = (
			q{ヤメテ ＞＜},
			q{あなたなんかに、この私をどうこうしようなんて１０年早いわ。＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /聞いて/o ){
		# 聞いて
		my @reply = (
			q{相談ごとなら人生経験豊富な boro さんか悶さんになさい。＞%s},
			q{イヤよ。＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	elsif( $args->{body} =~ /(かわいい|カワイイ|かわええ)/o ){
		# かわいい
		my @reply = (
			q{えっ・・ ///＞%s},
			q{も、もう１回言ってもらってもいい・・？ ///＞%s},
			q{私は生まれたときから美少女よ、当たり前じゃない。},
			q{それは私と付き合いたいって意思表示かしら。＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $who, $who, $who;
	}
	else{
		# ランダム
		return $self->_talk_random( $args );
	}
}

sub _talk_random {
	my $self = shift;
	my $args = shift or return;

	my ($msg) = shuffle @reply_random;
	return sprintf $msg, $args->{who}, $args->{who}, $args->{who};
}

sub _talk_neta {
	my $self = shift;
	my $args = shift or return;

	require XML::Feed;
	require WWW::Shorten::TinyURL;

	# -> 初音ミクみく
	if( my $feed = XML::Feed->parse( URI->new('http://vocaloid.blog120.fc2.com/?xml') ) ){
		my $entry;
		for my $e( shuffle $feed->entries ){
			next if $e->title =~ /常設/o;
			next if $e->title =~ /日/o;    # 本日などを除く
			
			$entry = $e;
			last;
		}
		if( $entry ){
			my $title = $entry->title;
			$title =~ s/^出た！[\s]*//o;
			$title =~ s/について$//o;
			return sprintf "%s: %s", $title, WWW::Shorten::TinyURL::makeashorterlink( $entry->link );
		}
	}

	return q{取得できなかったわ・・（泣};
}

sub _talk_hello {
	my $self = shift;
	my $args = shift or return;

	my ($msg) = shuffle @reply_random;
	return sprintf $msg, $args->{who}, $args->{who}, $args->{who};
}

1;

__END__
