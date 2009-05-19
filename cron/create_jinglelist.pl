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
# -t: local test mode

my $stash = {};

my $base_dir = defined $opt->{t} ? '.' : '/web/mikunopop/htdocs/jingle/';
my $template_file = file( $base_dir, "template", "jingle.html" )->stringify;
my $output_file = file( $base_dir, 'index.html' )->stringify;

my @jingle = (
	{
		video_id => 'sm6789292',
		vid => '6789292',
		title => '【初音ミク】近未来ラジオ【ジングル用】',
		author => 'ぎんさん',
		desc => 'ジングルその１。すべてはここから始まった！',
	},
	{
		video_id => 'sm6789315',
		vid => '6789315',
		title => '【初音ミク】近未来ラジオ【ジングル用】',
		author => 'ぎんさん',
		desc => 'ジングルその２。',
	},
	{
		video_id => 'sm6939234',
		vid => '6939234',
		title => '【ジングル】ミクノポップクエスト【sunlight loops】',
		author => '？さん',
		desc => '勇者あすたあの冒険編。',
	},
	{
		video_id => 'sm6981084',
		vid => '6981084',
		title => '【ジングル】ミクノポップをきかないか？ジングル【近未来ラジオver】',
		author => '？さん',
		desc => '',
	},
	{
		video_id => 'sm7007629',
		vid => '7007629',
		title => '【ジングル】音楽が降りてくる【lysosome】',
		author => '？さん',
		desc => 'A*ster「びにゅＰはおれの嫁」kotac「おれの嫁」higumon「おれの」saihane「俺」io「・・・」',
	},
	{
		video_id => 'sm7033805',
		vid => '7033805',
		title => '【ジングル】ミクノポップをきかないか？【Freestyle ver】',
		author => 'aoid さん',
		desc => '',
	},
	{
		video_id => 'sm7075450',
		vid => '7075450',
		title => '【ジングル】円の中の世界【EN】',
		author => '? さん',
		desc => '',
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
