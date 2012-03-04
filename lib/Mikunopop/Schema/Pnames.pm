package Mikunopop::Schema::Pnames;

use parent qw/DBIx::Class/;
use CLASS;

CLASS->load_components(qw/PK::Auto Core/);
CLASS->table('pnames');
CLASS->add_columns(qw(
	pid
	pname
	pname_alias
	description
	
	regist_date
	update_date
));
CLASS->set_primary_key('pid');

1;

__END__