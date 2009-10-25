# 

package Mikunopop::Ping;

use strict;
use 5.008;
use vars qw($VERSION);

use Apache2::Const -compile => qw(:common);
use Apache2::RequestRec ();

use utf8;

$VERSION = '0.01';

sub handler : method {    ## no critic
	my ($class, $r) = @_;

	# surpress annoying logging
	# -> 実際は OK 以外を返すべきではないとされている
	$r->set_handlers( PerlLogHandler => sub { return Apache2::Const::DONE } );


	### output & cleanup

	$r->content_type("text/plain");
	$r->content_languages( [ 'ja' ] );
	$r->print("ok.\n");

	# end
	return  Apache2::Const::OK;
}

return 1;

__END__
