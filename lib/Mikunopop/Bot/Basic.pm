package Mikunopop::Bot::Basic;

use strict;
use warnings;
use parent qw(Bot::BasicBot Mikunopop::Bot::Talk);
use List::Util qw(first shuffle);
use Path::Class qw(dir file);
use IO::File;
use Fcntl qw(:DEFAULT :flock);
use LWP::Simple;
use XML::Twig;
use JSON::Syck;
use DateTime;

use utf8;
use Encode;

my $base = '/web/mikunopop';
my $log_dir = dir( $base, qw(var irclog) );
my $status_file = file( $base, qw(htdocs var), "live_status.js" );
my $chat_status_file = file( $base, qw(htdocs var), "chat_status.js" );
my $count_file = file( $base, "htdocs", "play", "count.json" );
my $topic_global;

my @admin = (
	qr{^saihane(_.+)*}io,
	qr{^higumon(_.+)*}io,
	qr{^kotac(_.+)*}io,
	qr{^boro(_.+)*}io,
	qr{^k-sk(_.+)*}io,
	qr{^aoid(_.+)*}io,
	qr{^as(_.+)*}io,
	qr{^io(_.+)*}io,
	qr{^w2k(_.+)*}io,
	qr{^noren(_.+)*}io,
	qr{^mashita(_.+)*}io,
	qr{^A_?ster(_.+)*}io,
	qr{^kinuko(mochi)*(_.+)*}io,
	qr{^miyum(_.+)*}io,
	qr{^garana(_.+)*}io,
	qr{^sol(_.+)*}io,
	qr{^skyblue(_.+)*}io,
	qr{^yuu*ki[\-_]*mirai(_.+)*}io,
	qr{^Q[\-_]*iron(_.+)*}io,
	qr{^aki_housenka(_.+)*}io,
	qr{^Shaghar(_.+)*}io,
	qr{^Mint(_.+)*}io,
	qr{^cat+h+y(_.+)*}io,
	qr{^mega\-?ne(_.+)*}io,
	qr{^birdm9101(_.+)*}io,
	qr{^sumiwo(_.+)*}io,
	qr{^kawa(_.+)*}io,
	qr{^koke(_.+)*}io,
	qr{^yagyou(_.+)*}io,
	qr{^infee_koz(_.+)*}io,
	qr{^danjoh(_.+)*}io,
	qr{^kuranchi(_.+)*}io,
	qr{^hbho(_.+)*}io,
	qr{^karukaru(_.+)*}io,
	qr{^Sword(_.+)*}io,
	qr{^lefthorse(_.+)*}io,
	qr{^katakuri(_.+)*}io,
	qr{^deep(diver)?(_.+)*}io,
	qr{^tadi(_.+)*}io,
	qr{^orange(_.+)*}io,
	qr{^tatuta(_.+)*}io,
	qr{^aki(_.+)*}io,
);

my @me_regex = (
	qr{mikuno_chan}io,
	qr{(ミクノ|みくの)(ちゃ|チャ)(?![う])}io,
);

my $aircaster_table = {
	qr{saihane.*}io => q{羽},
	qr{さいはね.*}io => q{羽},
	qr{higumon.*}io => q{悶},
	qr{A\*?ster}io => q{あすたー},
	qr{io}io => q{いお},
	qr{mashita.*}io => q{真下},
	qr{マシータ.*} => q{真下},
	qr{kinuko.*}io => q{きぬこ},
	qr{aki_housenka.*}io => q{きぬこ},
	qr{noren.*}io => q{暖簾},
	qr{miyumm.*}io => q{みゅむ},
	qr{SOL.*}io => q{S.O.L},
	qr{yuu*ki[\-_]*.*}io => q{未来勇気},
	qr{skyblue.*}io => q{蒼空},
	qr{Q[\-_]*iron.*}io => q{９鉄},
	qr{aoid.*}io => q{aoid},
	qr{k-sk.*}io => q{k-sk},
	qr{sumiwo.*}io => q{すみを},
	qr{Shaghar.*}io => q{シャガ〜ル},
	qr{koke.*}io => q{コケ},
	qr{birdm9101.*}io => q{トリィ},
	qr{cat+h+y.*}io => q{cathy},
	qr{yagyou(_.+)*}io => q{百鬼夜行},
	qr{mega\-?ne(_.+)*}io => q{メガーネ君},
	qr{infee_koz(_.+)*}io => q{こず},
	qr{kuranchi(_.+)*}io => q{くらんち},
	qr{hbho(_.+)*}io => q{hbho},
	qr{danjoh(_.+)*}io => q{danjoh},
	qr{naniwa(_.+)*}io => q{naniwa},
	qr{karukaru(_.+)*}io => q{karukaru},
	qr{Sword(_.+)*}io => q{ソード},
	qr{lefthorse(_.+)*}io => q{左馬},
	qr{katakuri(_.+)*}io => q{かたくり},
	qr{alicia(_.+)*}io => q{アリシア},
	qr{tadi(_.+)*}io => q{たぢ},
	qr{orange(_.+)*}io => q{山北みかん},
};

my @ignore_hello = (
	qr{^saihane(_.+)*}io,
	qr{^higumon(_.+)*}io,
	qr{^mib_.+}io,
	qr{^mega\-ne(_.+)*}io,
	qr{^birdm9101(_.+)*}io,
	qr{^w2k(_.+)*}io,
	qr{^danjoh(_.+)*}io,
	qr{^karukaru(_.+)*}io,
	qr{^kawa(_.+)*}io,
);

my $tz = DateTime::TimeZone->new( name => 'Asia/Tokyo' );

sub init {
	my $self = shift;

	$self->logit( info => "# channel %s started on %s @ %s", $self->channels, scalar localtime, $self->server );

	$self->{_live_uri} = 0;

	return $self;
}

sub said {
	my $self = shift;
	my $args = shift;
	
	# normal
	my $pad = ' ' x ( 16 - length( $args->{who} ) - 1 );
	$self->logit( info => "%s: %s %s: %s", @{$args}{qw(channel who)}, $pad, $args->{body} );

	# info
	if( $args->{body} =~ /((sm|nm)\d{7,9})/o ){
		# log
		my $id = $1;
		my $info_url = sprintf "http://ext.nicovideo.jp/api/getthumbinfo/%s", $id;
		
		my $stash = {};
		if( $id and my $content = LWP::Simple::get( $info_url ) ){
			printf STDERR "debug: nico video info: %s\n", $id if $self->debug;
			
			my $handler = {};
			$handler->{'/nicovideo_thumb_response/thumb'} = sub {
				my ($tree, $elem) = @_;
				
				for my $item( $elem->children ){
					# get all
					my @key = qw(title description);
					
					for my $key( @key ){
						if( $item->name eq $key ){
							$stash->{$key} = $item->trimmed_text;
						}
					}
				}
			};
			
			# parse
			my $twig = XML::Twig->new( TwigHandlers => $handler );
			eval { $twig->parse( $content ) };
			
			if( defined $stash->{title} and $stash->{title} ne '' ){
				my $info_url = sprintf "http://mikunopop.info/info/%s", $id;
				my $msg = sprintf "%s %s", $stash->{title}, $info_url;
				
				# ミクノ度
				if( my $json_content = $count_file->slurp ){
					$json_content =~ s{^//.+\n}{}gsmo;
					if( my $json = eval { JSON::Syck::Load( $json_content ) } ){
						if( exists $json->{ $id } ){
							my $count = int $json->{ $id };
							$count =~ tr/0-9/０-９/;
							$msg .= sprintf " (彡%s)", $count;
						}
					}
				}
				
				$self->say(
					channel => $self->channels,
					body => $msg,
				);
				
				my $pad = ' ' x ( 16 - length( $self->nick ) - 1 );
				$self->logit( info => "%s: %s %s: %s", $args->{channel}, $self->nick, $pad, $msg );
			}
		}
	}
	elsif( first { $args->{body} =~ $_ } @me_regex ){
		# 呼ばれた時
		if( my $msg = $self->_talk( $args ) ){
			$self->_say( $args, $msg );
		}
	}
	
	return;
}

sub _say {
	my $self = shift;
	my ($args, $msg) = @_;

	sleep 1;
	$self->say(
		channel => $self->channels,
		body => $msg,
	);
	
	my $pad = ' ' x ( 16 - length( $self->nick ) - 1 );
	$self->logit( info => "%s: %s %s: %s", @{$args}{qw(channel)}, $self->nick, $pad, $msg );

	return $self;
}

sub chanjoin {
	my $self = shift;
	my $args = shift;

	$self->logit( info => "%s: %s joined.", @{$args}{qw(channel who)} );

	# なると配り
	if( first { $args->{who} =~ $_ } @admin ){
		$self->logit( info => "%s: +o", $args->{who} );
		$self->mode( $self->channels, '+o', $args->{who} );
	}

	# あいさつしない
	return
		if first { $args->{who} =~ $_ } @ignore_hello;

	# あいさつ
	if( $args->{who} ne $self->nick ){
		
		# 名前が test だったら警告を出す
		if( $args->{who} =~ /^(test|noname|demo).*/io ){
			{
				my $msg = sprintf q{* 大変申し訳ありません、混乱するので名前を変更して頂けますか？＞%sさん}, $args->{who};
				$self->_say( $args, $msg );
			}
			sleep 1;
			{
				my $msg = q{* たとえば、/nick taro と打つと、ニックネームを変えることができます。ご協力お願いします。m(_ _)m};
				$self->_say( $args, $msg );
			}
			return;
		}
		
=for
		my @reply_hello = (
			q{あら、%sさんいらっしゃい。},
		);
		
		# 時刻によって挨拶を変える
		my $now = DateTime->now( time_zone => $tz );
		my $hour = $now->hour;
		if( $hour >= 5 and $hour <10 ){
			push @reply_hello, (
				q{あら、%sさんおはよ。},
				q{お、おはよう・・///＞%s},
			);
		}
		elsif( $hour >= 10 and $hour <18 ){
			push @reply_hello, (
				q{あら、%sさんこんにちわ。},
				q{こんにちわですぅぅぅ！＞%sさん},
				q{い、いらっしゃい・・///＞%s},
				q{こんにちわ%sさん、ご機嫌いかが？},
			);
		}
		else{
			push @reply_hello, (
				q{こんばんわ、%sさん♪},
				q{あら、%sさんこんばんわ。},
				q{こんばんわですぅぅぅ！＞%sさん},
				q{%s兄さん、いらっしゃいですわ。},
				q{きょうは遅かったのね。＞%s},
				q{あらこんばんわ%sさん。},
				q{あらこんばんわ%sさん、ご機嫌はいかがかしら。},
				q{こんばんわ%sさん、よい晩ね。},
			);
		}
		
		my ($msg) = shuffle @reply_hello;
		my $who = $self->convert_aircaster( $args->{who} );
		
		$msg = sprintf $msg, $who;
		
		$self->_say( $args, $msg );
=cut
	}

	return;
}

sub chanpart {
	my $self = shift;
	my $args = shift;

	$self->logit( info => "%s: %s left.", @{$args}{qw(channel who)} );

	return;
}

sub topic {
	my $self = shift;
	my $args = shift;

	if( defined $args->{who} and $args->{who} ne '' ){
		$self->logit( info => "%s: %s changed topic to %s.", @{$args}{qw(channel who topic)} );
		
		$topic_global = $args->{topic};
	}
	else{
		my ($channel, $topic) = split ' ', $args->{channel}, 2;
		$self->logit( info => "%s: topic: %s.", $channel, $topic );
		
		$topic_global = $topic
	}

	return;
}

sub nick_change {
	my $self = shift;
	my ($from, $to) = @_;

	$self->logit( info => "%s nick changed to %s.", $from, $to );

	return;
}

my $last_uri = "";

sub tick {
	my $self = shift;

	my $sec = 20;

	# ３０秒に１回、ミクノの放送状況を告知
	my $json = JSON::Syck::Load( file( $status_file )->slurp );
	my $status = $json->{status};
	$json->{uri} ||= '';
	
	if( $self->{_live_uri} ne $json->{uri} ){
		
		if( $status == 1 and $json->{uri} ne $last_uri ){
			# 放送がはじまった
			
			my $msg;
			if( my $aircaster = $self->get_aircaster( $json->{uri} ) ){
				my @msg = (
					q{あら、%sさんが生放送を始めたわ。%s},
					q{どうやら%sさんの生放送が始まったようね。%s},
				);
				$msg = sprintf $msg[int(rand scalar @msg)], $aircaster, $json->{uri};
			}
			else{
				$msg = sprintf "あら、生放送が始まったようね。%s", $json->{uri};
			}
			
			my $pad = ' ' x ( 16 - length( $self->nick ) - 1 );
			$self->logit( info => "%s: %s %s: %s", $self->channels, $self->nick, $pad, $msg, );
			
			$self->say(
				channel => $self->channels,
				body => $msg,
			);
			
			$last_uri = $json->{uri};
			$sec = 60;
		}
		else{
			# 放送がおわった
			$sec = 20;
		}
		
		$self->{_live_uri} = $json->{uri} || '';
	}

	# チャット中の人数をファイルに吐く

	do {
		my $channel_data = $self->channel_data( $self->channels );
		
		my $num = scalar( keys %{ $channel_data } ) - 1;    # 自分を除く
		$num = 0 if $num < 0;
		
		my $name_list = {};
		for my $name( grep { ! /^mikuno_chan/io } keys %{ $channel_data } ){
			my $active = $name =~ /_(away|bath|o?(f|h)uro|work|afk|busy|gohan|rom|game|job|sagyou?|walk|sanpo|noc)$/io
				? "inactive"
				: "active";
			
			$name_list->{ $self->escape_html( $self->convert_aircaster( $name ) ) } = $active;
		}
		
		my @name = map { $self->convert_aircaster($_) } grep { ! /^mikuno_chan/io } keys %{ $channel_data };
		
		my $status = {
			num => $num,
			topic => $self->escape_html( $topic_global ),
			name => $name_list,
		};
		
		if( my $fh = $chat_status_file->openw ){
			$fh->print( JSON::Syck::Dump( $status ), "\n" );
			$fh->close;
		}
	};

	return $sec;
}

sub get_aircaster {
	my $self = shift;
	my $uri = shift or return;

	# <span id="pedia">( 放送者:<strong class="nicopedia"><a href="http://www.nicovideo.jp/user/11353010" target="_blank">boro</a></strong>さん)</span><br>	
	my $aircaster = "";
	if( my $content = LWP::Simple::get( $uri ) ){
		$content = eval { Encode::decode_utf8( $content ) } || $content;
		if( $content =~ m{user/\d+?" target="_blank">([^<>]+?)</a></strong>さん}msio ){    # "
			$aircaster = $1;
		}
	}
	$aircaster ||= '?';

	return $self->convert_aircaster( $aircaster );
}

sub convert_aircaster {
	my $self = shift;
	my $aircaster = shift or return;

	if( $aircaster =~ /^mib_/o ){
		$aircaster = q{名無しさん};
	}
	else{
		while( my ($from_regex, $to) = each %{ $aircaster_table } ){
			if( $aircaster =~ $from_regex ){
				$aircaster = $to;
			}
		}
	}

	$aircaster =~ s{_+$}{}o;

	return $aircaster;
}

sub prepare_fh {
	my $self = shift;

	$self->set_filename;

	return new IO::File $self->{filename}, O_WRONLY|O_APPEND|O_CREAT;
}

sub set_filename {
	my $self = shift;

	# rename for daily rotation
	# logfile = mikunopop_%04d%02d%02d.log
	my $filename = sprintf "mikunopop_%04d%02d%02d.log", $self->date_time;
	$self->{filename} = file( $log_dir, $filename )->stringify;

	return $self;
}

sub date_time {
	my $self = shift;
	my $time = shift || time;

	my @ds = localtime $time;
	$ds[4]++;
	$ds[5] += 1900;
	return @ds[5,4,3,2,1,0,6,7];
}

sub logit {
	my $self = shift;

	my ($method, $template, @args) = scalar @_ <= 1
		? ( debug => shift, ())
		: (@_);

	no warnings "uninitialized";

	$template = "(something's happened.)"    # '
		if $template eq '';
	my $msg = sprintf "[%s] $template", scalar localtime, @args;
	$msg =~ s/[\s\n]+$//o;
	
	if( utf8::is_utf8( $msg ) ){
		$msg = eval { Encode::encode_utf8( $msg ) } || $msg;
	}

	if( my $fh = $self->prepare_fh ){
		print {$fh} $msg, "\n";
		printf STDERR "%s\n", $msg;
	}
}

sub escape_html {
	my $self = shift;
	my $str = shift // "";

	$str =~ s{&}{&amp;}gso;
	$str =~ s{<}{&lt;}gso;
	$str =~ s{>}{&gt;}gso;
	$str =~ s{"}{&quot;}gso;    # "

	return $str;
}

1;

__END__
