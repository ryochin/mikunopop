#!/usr/bin/perl --

use strict;
use warnings;
use lib qw(lib /web/mikunopop/lib);
use Path::Class qw(file dir);
use List::Util qw(first shuffle);
use List::MoreUtils qw(uniq);
use LWP::Simple qw(get);
use YAML::Syck ();
use Data::Dumper;
use DateTime;
use DateTime::Format::MySQL;
use DateTime::Format::W3CDTF;
use XML::Twig;
use Getopt::Std;
use Term::ANSIColor;

use Mikunopop::Pnames;
use Mikunopop::Tags;
use Mikunopop::VideoInfo;
use Mikunopop::Schema;

use utf8;
use Encode;

local $ENV{DBIC_UNSAFE_AUTOCOMMIT_OK} = 1;

Getopt::Std::getopts 'vi:s:f' => my $opt = {};
# -v: verbose
# -i: single video id
# -s: sort type( default: random) [random/new/old]
# -f: force (ignore too new)

my $debug = defined $opt->{v};

my $base_dir = '/web/mikunopop/';
my $var_dir = file( $base_dir, "var" );
my $db_file = file( $var_dir, 'playlist.db' )->stringify;

my $hour = 2 * 24;

my $code = 'utf8';
my $dbiconfig = {
	AutoCommit => 0,    # transaction
#	RaiseError => 1,
	on_connect_do => [
		"SET CHARACTER SET $code",
		"SET NAMES $code",
		"SET SESSION senna_2ind=OFF",
	],
};
my $schema = Mikunopop::Schema->connect("dbi:mysql:database=mikunopop", "mikunopop", "mikunopop", $dbiconfig ) or die DBI->errstr;

my $now = DateTime->now( time_zone => 'Asia/Tokyo' );

my @video;
if( defined $opt->{i} ){
	# single
	my @list = grep { /^(sm|nm|so)\d+$/o }  split /[^0-9a-z]+/o, $opt->{i};
	for my $video( @{ YAML::Syck::LoadFile( $db_file ) } ){
		if( first { $video->{id} eq $_ } @list ){
			push @video, $video;
		}
	}
}
else{
	# multi
	printf STDERR "loading yaml file ...  " if $debug;
	
	my $sub = sub {
		( my $n = $a->{id} ) =~ s/^[^0-9]+//o;
		( my $m = $b->{id} ) =~ s/^[^0-9]+//o;
		return $n <=> $m;
	};
	
	if( defined $opt->{s} and $opt->{s} ne '' ){
		if( first { $opt->{s} eq $_ } qw(rand random) ){
			# random
			@video = shuffle @{ YAML::Syck::LoadFile( $db_file ) };
		}
		elsif( first { $opt->{s} eq $_ } qw(new) ){
			# new
			@video = reverse sort $sub @{ YAML::Syck::LoadFile( $db_file ) };
		}
		elsif( first { $opt->{s} eq $_ } qw(old) ){
			# new
			@video = sort $sub @{ YAML::Syck::LoadFile( $db_file ) };
		}
	} 
	else{
		# default
		@video = shuffle @{ YAML::Syck::LoadFile( $db_file ) };
	}
	
	printf STDERR "done.\n" if $debug;
}

my $cnt = 0;
for my $video( @video ){
	last if $cnt > 500;
	
	next if first { $video->{id} eq $_ } @{ $Mikunopop::VideoInfo::Deleted };
	
	if( my ($v) = $schema->resultset('Video')->search( { vid => $video->{id} } ) ){
		# 更新時刻をチェック
		my $update_date = DateTime::Format::MySQL->parse_datetime( $v->update_date );
		if( not defined $opt->{f} and $now->epoch - $update_date->epoch < $hour * 60 ** 2 ){
#			printf STDERR "% 12s: skip (too new)\n", $video->{id} if $debug;
			
			next;
		}
		else{
			# 更新
			if( my $result = &get_video_info( $video->{id} ) ){
				$cnt++;
				for my $key( qw(title description view_counter mylist_counter comment_num pnames tags) ){
					$v->$key( $result->{$key} );
				}
				$v->update_date( DateTime::Format::MySQL->format_datetime( $now ) );
				$v->update;
				
				printf STDERR "% 12s: updated\n", $video->{id} if $debug;
			}
			else{
				printf STDERR "% 12s: %sdeleted?%s\n", $video->{id}, color('red'), color('reset') if $debug;
			}
		}
	}
	else{
		# なければ埋める
		if( my $result = &get_video_info( $video->{id} ) ){
			$cnt++;
			printf STDERR "% 12s: new entry\n", $video->{id} if $debug;
			
			$schema->resultset('Video')->create( {
				vid => $video->{id},
				title => $result->{title},
				description => $result->{description},
				
				length => $result->{length},
				first_retrieve => DateTime::Format::MySQL->format_datetime( $result->{first_retrieve} ),
				
				view_counter => $result->{view_counter},
				mylist_counter => $result->{mylist_counter},
				comment_num => $result->{comment_num},
				
				pnames => $result->{pnames},
				tags => $result->{tags},
				
				regist_date => DateTime::Format::MySQL->format_datetime( $now ),
				update_date => DateTime::Format::MySQL->format_datetime( $now ),
			} );
		}
		else{
			printf STDERR "% 12s: %sdeleted?%s\n", $video->{id}, color('red'), color('reset') if $debug;
		}
	}
	
	# commit
	$schema->storage->txn_commit;
	
	sleep 2;
}

# cleanup
$schema->storage->txn_rollback;

exit 0;

sub get_video_info {
	my $id = shift or return;

	my $result = {};

	my $info_url = sprintf "http://ext.nicovideo.jp/api/getthumbinfo/%s", $id;

	if( my $content = get( $info_url ) ){
		my $handler = {};
		my @tag;
		$handler->{'/nicovideo_thumb_response/thumb'} = sub {
			my ($tree, $elem) = @_;
			
			for my $item( $elem->children ){
				# get all
				my @key = qw(title description thumbnail_url first_retrieve length view_counter comment_num mylist_counter watch_url last_res_body);
				
				for my $key( @key ){
					if( $item->name eq $key ){
						$result->{$key} = $item->trimmed_text;
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
		$result->{tags} = sprintf ":%s:", join ':', ( uniq @tag_vocaloid );
		
		if( defined $result->{title} and $result->{title} ne '' ){
			# pname
			$result->{pnames} = sprintf ":%s:", join ':', &Mikunopop::Pnames::get_pnames( @tag );
			
			# first_retrieve
			my $f = DateTime::Format::W3CDTF->new;
			$result->{first_retrieve} = eval { $f->parse_datetime( $result->{first_retrieve} ) };
		}
		else{
			return;
		}
	}

	return $result;
}

__END__
