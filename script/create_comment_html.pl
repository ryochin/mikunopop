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
use CGI;
use YAML::Syck;
local $YAML::Syck::ImplicitUnicode = 1;
use Data::Page;
use DateTime;
use Regexp::Common qw(URI);

use utf8;
#use bytes ();
use Encode;

binmode STDOUT, ':utf8';

# getopt
Getopt::Std::getopts 'b:n:' => my $opt = {};
# -b: base dir
# -n: least num

my $base_dir = $opt->{b} || '../';
my $yaml_dir = dir( $base_dir, 'var', 'comment' )->cleanup;
my $template_file = file( $base_dir, 'template', 'comment.html' );
my $meta_yml = file( $base_dir, 'var', 'comment', 'meta.yml' );

my $least_num = defined $opt->{n} ? int $opt->{n} : 1;

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

my $page = Data::Page->new;
$page->total_entries( max keys %{ $list } );
$page->entries_per_page( 1 );

my $template = &create_template;
for my $no( 1 .. $page->last_page ){
	next if $no < $least_num;
	next if not defined $list->{ $no };
	my $html_file = sprintf "%d.html", $no;
	my $dir = int( $no / 1000 );
	my $html = file( $base_dir, 'htdocs', 'comment', $dir, $html_file );
	$html->parent->mkpath if not -e $html->parent;
	
	# get data
	my $stash = YAML::Syck::LoadFile( $list->{$no} );
	
	# 前の放送を探す
	for( reverse 1 .. $no - 1 ){
		next if not defined $list->{$_};
		$stash->{prev_page} = $_;
		$stash->{prev_page_url} = sprintf "../%d/%d.html", int( $_ / 1000 ), $_;
		last;
	}
	
	# 次の放送を探す
	for( $no + 1 .. $page->last_page ){
		next if not defined $list->{$_};
		$stash->{next_page} = $_;
		$stash->{next_page_url} = sprintf "../%d/%d.html", int( $_ / 1000 ), $_;
		last;
	}
	
	# コメント整形
	for my $content( @{ $stash->{content} } ){
#		$content->{comment} = CGI::escapeHTML( $content->{comment} );    # すでにエスケープされているファイルをパースした結果だから必要ない
		
		# auto link
		$content->{comment} =~ s{(?!watch/)((sm|nm)[0-9]{7,})}{http://www.nicovideo.jp/watch/$1}go;
		$content->{comment} =~ s{($RE{URI}{HTTP})}{
			my $url = $1;
			if( $url =~ m{((sm|nm)[0-9]{7,})}io ){
				# 動画へのリンク
				sprintf q|<a href="http://www.nicovideo.jp/watch/%s" target="_blank" class="video" title="&lt;img src=&quot;http://niconail.info/%s&quot; /&gt;">%s</a>|,
					$1, $1, $1;
			}
			else{
				# 普通のリンク
				sprintf q|<a href="%s" target="_blank" rel="nofollow">%s</a>|, $url, $url;
			}
		}eg;
		
		$content->{comment} =~ s{\n}{<br />}go;
	}
	
	# start
	$stash->{start} = DateTime->from_epoch( epoch => $stash->{start}, time_zone => 'local' );
	
	# meta
	if( defined $meta->{ $no } and $meta->{ $no } ne '' ){
		$stash->{meta_info} = $meta->{ $no };
	}
	
	# output
	$template->process( $template_file->stringify, $stash, $html->stringify, binmode => ':utf8' )
		or die $template->error;
	
	printf STDERR "=> %s created.\n", $html;
}

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

