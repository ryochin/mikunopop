package Mikunopop::Schema::Video;

use base qw/DBIx::Class/;
use CLASS;

CLASS->load_components(qw/PK::Auto Core/);
CLASS->table('video');
CLASS->add_columns(qw(
	vid
	title
	description
	
	length
	first_retrieve
	
	view_counter
	mylist_counter
	comment_num
	
	pnames
	tags
	
	regist_date
	update_date
));
CLASS->set_primary_key('vid');

1;
