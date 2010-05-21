# 

package Mikunopop::CountSearch;

use strict;
use 5.008;
use vars qw($VERSION);
use Data::Dumper;
use Path::Class qw(file);
use List::Util qw(first max);
use List::MoreUtils qw(all);
use YAML::Syck ();
local $YAML::Syck::ImplicitUnicode = 1;    # utf8 flag on
use CGI;
use Data::Dumper;

use Apache2::Const -compile => qw(:common);
use Apache2::RequestRec ();
use Apache2::Log ();
use Apache2::Request ();

use Mikunopop::Pnames;
use Mikunopop::Tags;
use Mikunopop::Schema;

use utf8;
use Encode;

$VERSION = '0.01';

my $base_dir = '/web/mikunopop/';
my $var_dir = file( $base_dir, "var" );

my $db_file = file( $var_dir, 'playlist.db' );
my $template_file = file( $base_dir, "template", "count_search.html" )->stringify;

my $expire = 6 * 60 ** 2;    # 6hrs
my $last = 0;    # epoch
my $count;    # count container
my $max = 0;    # count container

my $code = 'utf8';
my $dbiconfig = {
#	AutoCommit => 0,    # transaction
#	RaiseError => 1,
	on_connect_do => [
		"SET CHARACTER SET $code",
		"SET NAMES $code",
		"SET SESSION senna_2ind=OFF",
	],
};
my $schema = Mikunopop::Schema->connect("dbi:mysql:database=mikunopop", "mikunopop", "mikunopop", $dbiconfig ) or die DBI->errstr;

sub handler : method {    ## no critic
	my ($class, $r) = @_;
	$r = Apache2::Request->new($r);

	# insert to memory
	if( time - $last > $expire ){
		$r->log_error("=> count file reloaded.");
		$count = YAML::Syck::LoadFile( $db_file->stringify );
		
		# 前処理
		for my $video( @{ $count } ){
			$max = $video->{view}
				if $video->{view} > $max;
			
			$video->{title} = Encode::decode_utf8( $video->{title} );
		}
		
		$last = time;
	}

	my $cgi = CGI->new;
	$cgi->charset('utf-8');

	my $stash = {};

	# from, to
	my $from = $stash->{from} = int $r->param('from') || 20;
	my $to = $stash->{to} = int $r->param('to') || $max;

	if( $from > $to ){
		($from, $to) = ($to, $from);
	}

	# query
	my $query = ( defined $cgi->param('query') and $cgi->param('query') ne '' )
		? $cgi->param('query')
		: "";

	$query = Encode::decode_utf8( $query );

	my @query;
	if( $query ne '' ){
		$query =~ s/^\s+//o;
		$query =~ s/\s+$//o;
		
		@query = split /[\s　]+/o, $query;
		@query = splice @query, 0, 3 if scalar @query > 3;
		
		$query = join ' ', @query;
	}

	# tag
	my $tag = ( defined $cgi->param('tag') and $cgi->param('tag') ne '' )
		? $cgi->param('tag')
		: "";

	my $tag_list = {};
	my @tags = @{ &mikuno_tags };
	for my $n( 0 .. scalar( @tags ) -1 ){
		$tag_list->{$n} = $tags[$n];
	}
	$tag_list->{""} = q/▼ タグ/;


	# prepare
	my @candidate;
	for my $video( @{ $count } ){
		next if $video->{view} < $from;
		next if $video->{view} > $to;
		
		push @candidate, $video->{id};
	}
	
	# get all
	my $where = {
		vid => { -in => [ @candidate ] }
	};
	
	my $video_list = {};    # vid => dbi obj
	for my $v( $schema->resultset('Video')->search( $where ) ){
		$video_list->{ $v->vid } = $v;
	}

	# main
	my @video;
	MAIN:
	for my $video( @{ $count } ){
#		next if $video->{view} < $from;
#		next if $video->{view} > $to;
		
		my $v = $video_list->{ $video->{id} } or next;
		
		# query
		if( scalar @query ){
			
			my $pnames = $v
				? Encode::decode_utf8( $v->pnames )
				: "";
			
			# 含む
			if( $pnames ne '' ){
				next MAIN if not all { $video->{title} =~ /$_/i  or $pnames =~ /$_/i } grep { ! /^-/ } @query;
			}
			else{
				next MAIN if not all { $video->{title} =~ /$_/i } grep { ! /^-/ } @query;
			}
			
			# 含まない
			for my $pattern( @query ){
				if( $pattern =~ /^-/o ){
					(my $pat = $pattern) =~ s/^-//o;
					next MAIN if $video->{title} =~ /$pat/;
					next MAIN if $pnames ne '' && $pnames =~ /$pat/;
				}
			}
		}
		
		# tag
		if( $tag ne '' ){
			next if not $v;
			my @tags = grep { $_ ne '' } split ':', Encode::decode_utf8( $v->tags );
			next if not first {  $_ =~ /^$tag_list->{ $tag }$/i } @tags;
		}
		
		# value
		$video->{pnames} = [];
		$video->{tags} = [];
		if( $v  ){
			# pnames
			$video->{pnames} = [ grep { $_ ne '' } split ':', Encode::decode_utf8( $v->pnames ) ];
			
			# tags
			$video->{tags} = [ grep { $_ ne '' } split ':', Encode::decode_utf8( $v->tags ) ];
			
			# etc
			for my $key( qw(length) ){
				$video->{$key} = $v->$key();
			}
		}
		
		push @video, $video;
	}

	# num
	$stash->{num} = scalar @video;
	$stash->{too_many} = 1
		if scalar @video > 500;

	$stash->{video} = [ @video ];
	$stash->{max} = $max;

	# range
	my @range = reverse 1 .. $max;
	my $range_label = { map { $_ => sprintf "%d 回", $_ } @range };

	# from
	$stash->{form}->{from} = $cgi->popup_menu(
		-name => 'from',
		-id => 'from',
		-values => [ @range ],
		-default => $from,
		-labels => $range_label,
		-override => 1,
		-class => 'user-input',
	);

	# to
	$stash->{form}->{to} = $cgi->popup_menu(
		-name => 'to',
		-id => 'to',
		-values => [ @range ],
		-default => $to,
		-labels => $range_label,
		-override => 1,
		-class => 'user-input',
	);


	# tags
	$stash->{form}->{tag} = $cgi->popup_menu(
		-name => 'tag',
		-id => 'tag',
		-values => [ "", sort { $a <=> $b } grep { /^\d+$/o } keys %{ $tag_list } ],
		-default => $tag,
		-labels => $tag_list,
		-override => 1,
		-class => 'user-input',
	);

	$stash->{query} = $query;

	# query
	# -> なぜか value が化ける
#	$stash->{form}->{query} = $cgi->textfield(
#		-name => 'query',
#		-id => 'query',
#		-default => $query,
#		-override => 0,
#		-size => 8,
#		-class => 'user-input',
#	);

	# etc
	$stash->{current_url} = $r->uri;

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

sub mikuno_tags {
	return [
	"ミクノ",
	"ミクノポップ",
	"MikuPOP",
	"ミクビエント",
	"ミクトランス",
	"ミクトロニカ",
	"ミニマル",
	"ミクボッサ",
	"ミックンベース",
	"MikuHouse",
	"ボカノバ",
	"ChipTune",
	"Instrumental",
	"テクノ",
	"テクノポップ",
	"VOCALOID和風曲",
	"ミクウェーブ",
	"VOCALOID-EUROBEAT",
	"ボカロコア",
	"VOCALOUD",
	"Chiptune×VOCALOIDリンク",
	"--------",
	"みんなのミクうた",
	"初音ミク処女作",
	"切ないミクうた",
	"爽やかなミクうた",
	"クールなミクうた",
	"元気が出るミクうた",
	"隠れたミク名曲",
	"ミクちゃんといっしょ",
	"かわいいミクうた",
	"ききいるミクうた",
	"ミクのクリスマス曲",
	"ミクという音源を使ってみた",
	"初音ミク迷曲リンク",
	"大人のミク曲",
	"素朴なミクうた",
	"ごきげんミクさん",
	"なごみく",
	"元気が減るミクうた",
	"全部初音ミク",
	"全部ミク",
	"エロかわいいミクうた",
	"--------",
	"隠れたリン名曲",
	"鏡音リン迷曲リンク",
	"鏡音リン名曲リンク",
	"みんなのリンうた",
	"切ないリンうた",
	"元気が出るリンうた",
	"爽やかなリンうた",
	"かわいいリンうた",
	"クールなリンうた",
	"恋するリンうた",
	"ききいるリンうた",
	"ホットなリンうた",
	"素朴なリンうた",
	"元気の出るリンうた",
	"--------",
	"巡音ルカ名曲リンク",
	"ききいるルカうた",
	"クールなルカうた",
	"切ないルカうた",
	"隠れたルカ名曲",
	"爽やかなルカうた",
	"みんなのルカうた",
	"やさしいルカうた",
	"かわいいルカうた",
	"--------",
	"かわいいGUMIうた",
	"ききいるGUMIうた",
	"--------",
	"時田トリビュート",
	"ジャガボンゴ",
	"わりばしおんな。",
	"ProjectDIVA-AC楽曲募集",
	];
}

1;

__END__

