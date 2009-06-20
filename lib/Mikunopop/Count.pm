# 
# /count/sm7654321

package Mikunopop::Count;

use strict;
use 5.008;
use vars qw($VERSION);
use YAML::Syck ();
use JSON::Syck ();

use Apache2::Const -compile => qw(:common);
use Apache2::RequestRec ();

$VERSION = '0.01';

my $db = '/web/mikunopop/var/count.yml';
my $expire = 6 * 60 ** 2;    # 6hrs
my $last = 0;    # epoch
my $video;    # cache

sub handler : method {    ## no critic
	my ($class, $r) = @_;

	# insert to memory
	if( time - $last > $expire ){
		$video = YAML::Syck::LoadFile( $db );
	}

	# 回数を探して返す
	my $id = $r->path_info;
	$id =~ s{^/+}{}o;
	my $count = defined $video->{ $id }
		? $video->{ $id }
		: 0;

	# out
	$r->content_type("text/javascript");
	$r->print( JSON::Syck::Dump( { count => $count } ) );

	return Apache2::Const::OK;
}

1;

__END__

