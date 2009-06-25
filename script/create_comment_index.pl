#!/usr/bin/perl --
# ./convert_comment_html2yaml.pl ~/Desktop/1008.html > ../var/comment/1/1008.yml

use strict;
use warnings;
use Getopt::Std;
use Path::Class qw(file dir);
use IO::Handle;
use File::Basename;
use List::Util  qw(first max);
use Data::Dumper;
use YAML::Syck;
local $YAML::Syck::ImplicitUnicode = 1;
use DateTime;

use utf8;
#use bytes ();
use Encode;

binmode STDOUT, ':utf8';

# getopt
Getopt::Std::getopts 'b:' => my $opt = {};
# -b: base dir

my $base_dir = $opt->{b} || '../';
my $yaml_dir = dir( $base_dir, 'var', 'comment' )->cleanup;
my $template_file = file( $base_dir, 'template', 'comment_index.html' );
my $html = file( $base_dir. 'htdocs', 'comment', 'index.html' );
my $meta_yml = file( $base_dir, 'var', 'comment', 'meta.yml' );

my $meta = YAML::Syck::LoadFile( $meta_yml ) or die $!;

my $list = {};    # no => file obj
while ( my $dir = $yaml_dir->next) {
	next if not $dir->is_dir;
	next if $dir !~ m{/\d+$}o;
	
	while ( my $f = $dir->next) {
		next if $f !~ m{/\d+\.yml$}o;
		( my $no = $f->basename ) =~ s/\.yml$//o;
		$list->{ $no } = $f;
	}
}

my @html;
for my $no( 1 .. max keys %{ $list } ){
	next if not defined $list->{ $no };
	
	my $db = YAML::Syck::LoadFile( $list->{$no} );

	printf STDERR "%d ", $no;
	
	my $path = sprintf "./%d/%d.html", int( $no / 1000 ), $no;
		
	push @html, {
		no => $no,
		path => $path,
		start => DateTime->from_epoch( epoch => $db->{start}, time_zone => 'local' ),
		aircaster => $db->{aircaster},
		frame => $db->{frame},
		meta_info => $meta->{ $no },
	};
}
printf STDERR "\n";

my $stash = {};

for my $no( reverse @html ){
	push @{ $stash->{live} }, $no;
}

# output
my $template = &create_template;
$template->process( $template_file->stringify, $stash, $html->stringify, binmode => ':utf8' )
	or die $template->error;

printf STDERR "=> done.\n";

exit 0;

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

sub usage {
	*STDOUT->printf("usage: %s <html file>, [<html file>] ...\n", File::Basename::basename( $0 ));
	exit 1;
}

__END__

