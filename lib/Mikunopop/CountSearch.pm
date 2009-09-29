# 

package Mikunopop::CountSearch;

use strict;
use 5.008;
use vars qw($VERSION);
use Data::Dumper;
use Path::Class qw(file);
use List::Util qw(first max);
use YAML::Syck ();
local $YAML::Syck::ImplicitUnicode = 1;    # utf8 flag on
use CGI;

use Apache2::Const -compile => qw(:common);
use Apache2::RequestRec ();
use Apache2::Log ();
use Apache2::Request ();

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

	my $stash = {};

	# from, to
	my $from = $stash->{from} = int $r->param('from') || 20;
	my $to = $stash->{to} = int $r->param('to') || $max;

	if( $from > $to ){
		($from, $to) = ($to, $from);
	}

	# main
	my @video;
	for my $video( @{ $count } ){
		next if $video->{view} < $from;
		next if $video->{view} > $to;
		push @video, $video;
	}

	# num
	$stash->{num} = scalar @video;
	$stash->{too_many} = 1
		if scalar @video > 1000;

	$stash->{video} = [ @video ];
	$stash->{max} = $max;
	
	my $cgi = CGI->new;

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

