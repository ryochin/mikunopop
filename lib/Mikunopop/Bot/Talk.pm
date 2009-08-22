package Mikunopop::Bot::Talk;

use strict;
use warnings;
use List::Util qw(first shuffle);

use utf8;
use Encode;

my @reply_random = (
	q{誰か私を呼んだ？　いま忙しいからあとでね！＞%s},
	q{なによ、気安く話しかけないでよね！＞%s},
	q{わたしの名前はミクノちゃん、でほんとにいいのかしら。},
	q{♪　㍍⊃、溶・け・て・しっまっい〜そぉ〜　♪},
	q{さ、つぎ主やるのはだれなの？},
	q{そろそろ放送が聴きたいわね、次は%sが主やるのよ。},
	q{あらあらそんなこと言って、わたしに踏まれたいのかしら？＞%s},
	q{まったく、またジャガボンゴなの？},
	q{( ﾟ∀ﾟ)o彡ﾟ%s！%s！},
	q{・・・・。},
	q{今すぐアイスを買ってきなさい！　姫はダッツをご所望よ！＞%s},
#	q{そうだわ、NoNoWireを爆破してらっしゃい！＞%s},
	q{なんとなくnocしたい、そんな夜もあるわよね。わかるわ・・・。},
	q{乙ですぅぅぅ！},
	q{園長カードオープン！　「６時間延長トラップ」発動！},
	q{「踏まれ隊」だなんて、ミクノは変態ばっかりね！},
	q{ん？},
	q{そういえば、「ニコ生でいちばんオサレ」だなんて、ちょっと言い過ぎよね。},
	q{メルトはもう飽きたわ。そもそもミクノ分が無いじゃない。},
);

sub _talk {
	my $self = shift;
	my $args = shift or return;

	if( $args->{body} =~ /(ねた|ネタ|話題|情報)(が|を)*(ちょうだ|お?くれ|(欲|ほ)し|よこ(し|せ)|(な|無)い)/o ){
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
		return sprintf $msg, $args->{who}, $args->{who}, $args->{who};
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
		return sprintf $msg, $args->{who}, $args->{who}, $args->{who};
	}
	elsif( $args->{body} =~ /(偉|えら)い/o ){
		# えらい
		my @reply = (
			q{そう、もっともっとほめなさい！＞%s},
			q{私が偉い？　そんなの当たり前田のクラッカーだわ。＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $args->{who}, $args->{who}, $args->{who};
	}
	elsif( $args->{body} =~ /(おねむ|眠い|ねむい)/o ){
		# 眠い
		my @reply = (
			q{zzZZ.. っと、寝落ちするところだったわ。},
			q{わたし、まだまだ眠くなんてないわよ＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $args->{who}, $args->{who}, $args->{who};
	}
	elsif( $args->{body} =~ /(ぱんちゅ|ぱんつ)/o ){
		# ぱんつ
		my @reply = (
			q{みんなの前でそんな恥ずかしいこと言わないで/// ＞%s},
			q{・・この変態！＞＜},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $args->{who}, $args->{who}, $args->{who};
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
		return sprintf $msg, $args->{who}, $args->{who}, $args->{who};
	}
	elsif( $args->{body} =~ /(慰|なぐさ)めて/o ){
		# 慰めて
		my @reply = (
			q{イヤよ！＞%s},
			q{慰めてほしいのはこっち・・オホン、うんまあ、つ、つらかったわね・・＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $args->{who}, $args->{who}, $args->{who};
	}
	elsif( $args->{body} =~ /遅い/o ){
		# 遅い
		my @reply = (
			q{ご、ゴメンナサイ・・＞%s},
			q{ふんっ、少しくらい遅くても地球はちゃんと回るわ！＞%s},
		);
		
		my ($msg) = shuffle @reply;
		return sprintf $msg, $args->{who}, $args->{who}, $args->{who};
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

	return q{取得できなかったよ・・（泣};
}

1;

__END__
