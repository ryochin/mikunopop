# 
# /info/sm7654321

package Mikunopop::Info;

use strict;
use 5.008;
use vars qw($VERSION);
use Data::Dumper;
use Path::Class qw(file);
use List::Util qw(first);
use List::MoreUtils qw(uniq);
use DateTime;
use DateTime::Format::W3CDTF;
use JSON::XS ();
use LWP::Simple qw(get);
use XML::Twig;

use Mikunopop::Pnames;
use Mikunopop::Tags;

use Apache2::Const -compile => qw(:common);
use Apache2::RequestRec ();
use Apache2::Log ();
use Apache2::Request ();

use utf8;

$VERSION = '0.01';

my $base = '/web/mikunopop';
my $template_file = file( $base, "template", "info.html" )->stringify;

my $json_file = file( $base, 'htdocs/play/count.json' );
my $expire = 6 * 60 ** 2;    # 6hrs
my $last = 0;    # epoch
my $count;    # count container

sub handler : method {    ## no critic
	my ($class, $r) = @_;
	$r = Apache2::Request->new($r);

	# insert to memory
	if( time - $last > $expire ){
		$r->log_error("=> count file reloaded.");
		my $text = $json_file->slurp;
		$text =~ s{^//.+?\n}{}om;    # 頭につけているコメント部分を削る
		$count = JSON::XS::decode_json( $text );
		$last = time;
	}

	my $id;
	if( $r->param('id') =~ m{^.+((sm|nm)\d+)\s*$}o ){
		# http://www.nicovideo.jp/watch/sm6626954
		# リクです〜sm6626954
		$id = $1;
	}
	elsif( $r->param('id') =~ m{^(sm|nm)\d+\s*$}o ){
		# sm6626954
		$id = $r->param('id');
	}
	elsif( $r->param('id') =~ m{^\d+\s*$}o ){
		# 6626954
		# -> sm を補完する
		$id = sprintf "sm%d", $r->param('id');
	}
	else{
		# path_info から得る
		$id = $r->path_info;
		$id =~ s{^/+}{}o;
	}

	$id =~ s/\s+//go;

	my $stash = {};
	$stash->{id} = $id;

	my $info_url = sprintf "http://ext.nicovideo.jp/api/getthumbinfo/%s", $id;

	if( $id and my $content = get( $info_url ) ){
		my $handler = {};
		my @tag;
		$handler->{'/nicovideo_thumb_response/thumb'} = sub {
			my ($tree, $elem) = @_;
			
			for my $item( $elem->children ){
				# get all
				my @key = qw(title description thumbnail_url first_retrieve length view_counter comment_num mylist_counter watch_url last_res_body);
				
				for my $key( @key ){
					if( $item->name eq $key ){
						$stash->{$key} = $item->trimmed_text;
					}
				}
				
				# all tag
				if( $item->name eq 'tags' and $item->att('domain') eq 'jp' ){
					for my $t( $item->children ){
						next if $t->trimmed_text eq q{音楽};
						push @tag, $t->trimmed_text;
					}
				}
			}
		};
		
		# parse
		my $twig = XML::Twig->new( TwigHandlers => $handler );
		eval { $twig->parse( $content ) };
		
		# vocaloid tag
		my @tag_vocaloid;
		for my $tag( @tag ){
			# first が使えない
			for my $t( @{ $Mikunopop::Tags::Tags } ){
				if( $tag =~ /^$t$/i ){
					push @tag_vocaloid, $tag;
				}
			}
		}
		
		# set
		$stash->{tag} = [ @tag ];
		$stash->{tag_vocaloid} = [ uniq @tag_vocaloid ];
		
		if( defined $stash->{title} and $stash->{title} ne '' ){
			$stash->{has_info} = 1;
			
			# pname
			if( my @pname = &Mikunopop::Pnames::get_pnames( @{ $stash->{tag} } ) ){
				$stash->{pnames} = [ @pname ];
				$stash->{pname} = join ' ', @pname;
			}
			else{
				$stash->{pname} = "Ｐ名？";
			}
			
			# first_retrieve
			my $f = DateTime::Format::W3CDTF->new;
			$stash->{first_retrieve} = eval { $f->parse_datetime( $stash->{first_retrieve} ) };
			
			my $tz = DateTime::TimeZone->new( name => 'local' );
			my $now = DateTime->now( time_zone => $tz );
			
			eval {
				if( $now->epoch - $stash->{first_retrieve}->epoch < 7 * 24 * 60 ** 2 ){
					$stash->{is_too_new} = 1;
				}
			};
			
			# マイリス率
			$stash->{mylist_percent} = sprintf "%.1f", $stash->{mylist_counter} / $stash->{view_counter} * 100;
			
			# ミクノ度
			if( defined $count->{$id} and $count->{$id} > 0 ){
				$stash->{count} = $count->{$id};
			}
			else{
				$stash->{count} = '0';
			}
		}
		else{
			$stash->{not_found} = 1;
		}
	}

	# out
	my $template = &create_template;

	$r->content_type("text/html; charset=UTF-8");
	$template->process( $template_file, $stash, $r, binmode => ':utf8' )
		or die ;

	return Apache2::Const::OK;
}

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

1;

__END__

