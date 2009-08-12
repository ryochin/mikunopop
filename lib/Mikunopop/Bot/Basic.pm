package Mikunopop::Bot::Basic;

use strict;
use warnings;
use parent qw(Bot::BasicBot);
use List::Util qw(first shuffle);
use Path::Class qw(dir file);
use IO::File;
use Fcntl qw(:DEFAULT :flock);
use LWP::Simple;
use XML::Twig;
use JSON::Syck;

use utf8;
use Encode;

my $base = '/web/mikunopop';
my $log_dir = dir( $base, qw(var irclog) );
my $status_file = file( $base, qw(htdocs var), "live_status.js" );

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
);

my @me_regex = (
	qr{mikuno_chan}io,
	qr{(ミクノ|みくの)(ちゃ|チャ)}io,
);

my @reply = (
	q{誰か私を呼んだ？　いま忙しいからあとでね！＞%s},
	q{なによ、気安く話しかけないでよね！＞%s},
	q{おかえりなさいませ、%s様♪},
	q{き、来てくれてありがと・・なんて言うわけないでしょっ///＞%s},
	q{わたしの名前はミクノちゃん、でほんとにいいのかしら。},
	q{♪　㍍⊃、溶・け・て・しっまっい〜そぉ〜　♪},
	q{さ、つぎ主やるのはだれなの？},
	q{あらあらそんなこと言って、わたしに踏まれたいのかしら？＞%s},
);

sub init {
	my $self = shift;

	$self->logit( info => "# channel %s started on %s @ %s", $self->channels, scalar localtime, $self->server );

	$self->{_live_uri} = 0;

	return $self;
}

sub said {
	my $self = shift;
	my $args = shift;
	
	# info
	if( $args->{body} =~ /((sm|nm)\d{7,9})/o ){
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
		my ($msg) = shuffle @reply;
		$msg = sprintf $msg, $args->{who};
		
		sleep 2;
		$self->say(
			channel => $self->channels,
			body => $msg,
		);
		
		my $pad = ' ' x ( 16 - length( $args->{who} ) - 1 );
		$self->logit( info => "%s: %s %s: %s", @{$args}{qw(channel who)}, $pad, $msg );
	}
	else{
		# normal
		my $pad = ' ' x ( 16 - length( $args->{who} ) - 1 );
		$self->logit( info => "%s: %s %s: %s", @{$args}{qw(channel who)}, $pad, $args->{body} );
	}
	
	return;
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
	}
	else{
		my ($channel, $topic) = split ' ', $args->{channel}, 2;
		$self->logit( info => "%s: topic: %s.", $channel, $topic );
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
	
	if( $self->{_live_uri} ne $json->{uri} ){
		
		if( $status == 1 and $json->{uri} ne $last_uri ){
			# 放送がはじまった
			
			my $msg = sprintf "[生放送] %s (%sさん)", $json->{uri}, $self->get_aircaster( $json->{uri} );
			
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
		
		$self->{_live_uri} = $json->{uri};
	}

	return $sec;
}

sub get_aircaster {
	my $self = shift;
	my $uri = shift or return;

	my $aircaster = "";
	if( my $content = LWP::Simple::get( $uri ) ){
		$content = eval { Encode::decode_utf8( $content ) } || $content;
		if( $content =~ m{放送者：</b><span class="nicopedia">([^<>]+?)</span>}msio ){
			$aircaster = $1;
		}
	}
	$aircaster ||= '?';

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
use Devel::SimpleTrace;
	if( my $fh = $self->prepare_fh ){
		print {$fh} $msg, "\n";
		printf STDERR "%s\n", $msg;
	}
}

1;

__END__
