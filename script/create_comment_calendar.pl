#!/usr/bin/perl --

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
my $meta_yml = file( $base_dir, 'var', 'comment', 'meta.yml' );

my $meta = YAML::Syck::LoadFile( $meta_yml ) or die $!;

my $list = {};    # no => file obj
while ( my $dir = $yaml_dir->next) {
	next if not $dir->is_dir;
	next if $dir !~ m{/\d+$}o;
	
	while ( my $f = $dir->next) {
		next if $f !~ m{/\d+[\d\.]+\.yml$}o;
		( my $no = $f->basename ) =~ s/\.yml$//o;
		$list->{ $no } = $f;
	}
}

my $tz = DateTime::TimeZone->new( name => 'Asia/Tokyo' );

my $data = {};    # y => { m => { d => [ {}, {} .. ] } } }
for( my $no = max keys %{ $list }; $no >= 1; $no -= 0.5 ){
	next if not defined $list->{ $no };
	
	my $db = YAML::Syck::LoadFile( $list->{$no} );

	my $path = sprintf "/comment/%d/%s.html", int( $no / 1000 ), $no;
	
	my $start = eval { DateTime->from_epoch( epoch => $db->{start}, time_zone => $tz ) }
		or die;
	
	unshift @{ $data->{$start->year}->{$start->month}->{$start->day} }, {
		no => $no,
		path => $path,
		start => $start,
		aircaster => $db->{aircaster},
		frame => $db->{frame},
		meta_info => $meta->{ $no },
	};
}

my $now = DateTime->now( time_zone => $tz );

for my $year( sort { $a <=> $b } keys %{ $data } ){
	for my $month( sort { $a <=> $b } keys %{ $data->{$year} } ){
		my $stash = {
			year => $year,
			month => $month,
		};

		## カレンダー

		my $first = DateTime->new( time_zone => $tz, year => $year, month => $month, day => 1 );
		my $padding = $first->dow - 1;
		
		$stash->{cal} = [];
		$stash->{cal}->[0] = [];
		push @{ $stash->{cal}->[0] }, { live => undef } for 1 .. $padding;

		my $week = 1;
		my $w_num = 0;
		for my $day( 1 .. DateTime->last_day_of_month( year => $year, month => $month )->day ){
			my $today = DateTime->new( time_zone => $tz, year => $year, month => $month, day => $day );
			
			if( $today->dow == 1 ){
				$week++;
				$w_num = 0;
			}
			
			push @{ $stash->{cal}->[ $week - 1 ] }, {
				day => $day,
				live => $data->{$year}->{$month}->{$day},
			};
			$w_num++;
		}

		if( my $pad = 7 - $w_num ){
			push @{ $stash->{cal}->[ $week - 1 ] }, { list => undef } for 1 .. $pad;
		}

		## 一覧
		
		$stash->{list} = [];
		$week = 1;
		for my $day( 1 .. DateTime->last_day_of_month( year => $year, month => $month )->day ){
			my $today = DateTime->new( time_zone => $tz, year => $year, month => $month, day => $day );
			last if $today >= $now;
			
			push @{ $stash->{list} }, {
				date => $today,
				live => $data->{$year}->{$month}->{$day},
			};
		}
		
		@{ $stash->{list} } = reverse @{ $stash->{list} };
		
		# output
		my $template_file = file( $base_dir, 'template', 'comment_calendar.html' );
		my $html = file( $base_dir. 'htdocs', 'comment', $year, sprintf "%02d.html", $month );
		mkdir $html->parent if not -e $html->parent;
		my $template = &create_template;
		$template->process( $template_file->stringify, $stash, $html->stringify, binmode => ':utf8' )
			or die $template->error;
		
	}
}

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

