#!/usr/bin/perl --

use strict;
use warnings;
use Path::Class qw(file dir);
use IO::Handle;
use File::Basename;
use List::Util qw(first);
use CGI;
use Template;
use DateTime;
use LWP::Simple qw(get);
use Getopt::Std;

use utf8;
use Encode;

# getopt
Getopt::Std::getopts 't' => my $opt = {};

my $stash = {};

my $base_dir = '/web/mikunopop/';
my $htdocs_dir = file( $base_dir, "htdocs" );

my $template_file = file( $base_dir, "template", "jingle.html" )->stringify;
my $output_file = file( $htdocs_dir, "jingle", 'index.html' )->stringify;

my @jingle = (
	{
		video_id => 'sm6789292',
		vid => '6789292',
		title => '【初音ミク】Freestyle【ジングル用】',
		author => 'ぎんさん',
		length => '1:55',
		desc => 'ジングルその１。すべてはここから始まった！',
	},
	{
		video_id => 'sm6789315',
		vid => '6789315',
		title => '【初音ミク】近未来ラジオ【ジングル用】',
		author => 'ぎんさん',
		length => '1:50',
		desc => 'ジングルその２。',
	},
	{
		video_id => 'sm6939234',
		vid => '6939234',
		title => '【ジングル】ミクノポップクエスト【sunlight loops】',
		author => 'きぬこもちさん',
		length => '2:22',
		desc => '勇者あすたあの冒険編。',
	},
	{
		video_id => 'sm6981084',
		vid => '6981084',
		title => '【ジングル】ミクノポップをきかないか？ジングル【近未来ラジオver】',
		author => 'k-sk さん',
		length => '1:47',
		desc => '',
	},
	{
		video_id => 'sm7007629',
		vid => '7007629',
		title => '【ジングル】音楽が降りてくる【lysosome】',
		author => 'きぬこもちさん',
		desc => 'A*ster「びにゅＰはおれの嫁」kotac「おれの嫁」higumon「おれの」saihane「俺」io「・・・」',
		length => '2:08',
	},
	{
		video_id => 'sm7033805',
		vid => '7033805',
		title => '【ジングル】ミクノポップをきかないか？【Freestyle ver.A】',
		author => 'aoid さん',
		length => '1:56',
		desc => '',
	},
	{
		video_id => 'sm7075450',
		vid => '7075450',
		title => '【ジングル】円の中の世界【EN】',
		author => 'きぬこもちさん',
		length => '2:48',
		desc => '',
	},
	{
		video_id => 'sm7539326',
		vid => '7539326',
		title => '【ジングル】ミクノポップをきかないか？ジングル【Freestyle ver.K】',
		author => 'k-sk さん',
		length => '1:56',
		desc => '',
	},
	{
		video_id => 'sm7870758',
		vid => '7870758',
		title => '【NoNoWire用ジングル】ミクノポップをきかないか？【Freestyle ver.N】',
		author => 'きぬこもちさん',
		length => '1:56',
		desc => '黄猫隊長率いる「ルカ様に踏まれ隊」隊歌。',
	},
);

my $n = 0;
for my $jingle( @jingle ){
	$n++;
	unshift @{ $stash->{video} }, {
		n => $n,
		%{ $jingle },
	};
}

my $template = &create_template;
$template->process( $template_file, $stash, $output_file, binmode => ':utf8' )
	or die $template->error;

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
	*STDOUT->printf("usage: %s <html file>\n", File::Basename::basename( $0 ));
	exit 1;
}

__END__
