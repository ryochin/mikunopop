#!/usr/bin/perl --

use strict;
use warnings;
use lib qw(lib /web/mikunopop/lib);
use Path::Class qw(file);
use JSON::Syck ();
use Term::ProgressBar;
use Time::HiRes ();
use Config::Pit;

use Mikunopop::Schema;

use utf8;

my $base_dir = '/web/mikunopop/';
my $htdocs_dir = file( $base_dir, "htdocs" );
my $json_file = file( $htdocs_dir, "play", 'count.json' );

# read
my $content = $json_file->slurp;
$content =~ s{^//.+\n}{}gsmo;
my $list = JSON::Syck::Load( $content ) or die $!;

my $config = Config::Pit::pit_get("mysql/ryo", require => {
	username => "username",
	password => "password",
} );

my $dbiconfig = {
	AutoCommit => 1,    # transaction
};
my $schema = Mikunopop::Schema->connect("dbi:mysql:database=mikunopop", @{$config}{qw(username password)}, $dbiconfig ) or die DBI->errstr;

my $progress = Term::ProgressBar->new( { name => "video", count => scalar( keys %{ $list } ), ETA => 'linear' } );

my $cnt = 0;
while( my ($vid, $count) = each %{ $list } ){
	if( my ($video) = $schema->resultset('Video')->search( { vid => $vid }, { order_by => \ 'vid', columns => [ qw(vid count) ] } )->slice( 0, 1 ) ){
		$video->count( $list->{ $vid } );
		$video->update;
	}
	$progress->update( ++$cnt );
	Time::HiRes::usleep 20_000;
}

__END__
