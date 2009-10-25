#!/usr/bin/perl --

use strict;
use warnings;
use lib qw(lib /web/mikunopop/lib);
use Path::Class qw(file dir);
use IO::Handle;
use File::Basename;
use List::Util qw(first);
use CGI;
use LWP::Simple qw(get);
use YAML::Syck ();
use Text::CSV_XS;
use Compress::Zlib;

use Mikunopop::Schema;

use utf8;
use Encode;

my $code = 'utf8';
my $dbiconfig = {
#	AutoCommit => 0,    # transaction
#	RaiseError => 1,
	on_connect_do => [
		"SET CHARACTER SET $code",
		"SET NAMES $code",
	],
};
my $schema = Mikunopop::Schema->connect("dbi:mysql:database=mikunopop", "mikunopop", "mikunopop", $dbiconfig ) or die DBI->errstr;

my $stash = {};

my $base_dir = '/web/mikunopop/';
my $var_dir = file( $base_dir, "var" );
my $htdocs_dir = file( $base_dir, "htdocs" );
my $template_dir = file( $base_dir, "template" );

my $db_file = file( $var_dir, 'playlist.db' )->stringify;
my $template_file = file( $template_dir, 'award_3rd.html' )->stringify;
my $html_file = file( $htdocs_dir, 'award', '3rd_albums.html' )->stringify;

my $uri_list = [
	'http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/1254829253/2-',
];

my $content;
for my $uri( @{ $uri_list } ){
	if( my $c = get( $uri ) ){
		printf STDERR "uri: %s: ok.\n", $uri;
		$content .= eval { Encode::decode( 'euc-jp', $c ) } || $c;
	}
	else{
		printf STDERR "uri: %s: failed.\n", $uri;
	}
	sleep 1;
}

my $no = 0;
MAIN:
for my $line( split /\n/o, $content ){
	next if $line !~ /<dt>/o;
	chomp $line;
	$line = CGI::unescapeHTML( $line );
	
	next MAIN
		if $line =~ /投票用スレッドです/o;
	next MAIN
		if $line =~ /mailto:sage/o;
	
	$no++;
	
	my $name;
	if( $line =~ m{<font color="#008800"><b>([^<>]+?)</b></font>}o ){
		$name = $1;
	}
	
	my @v;
	my @comment;
	for my $data( split m{<(br|dd)>}, $line ){
		# コメント
		if( $data !~ /^\s*?[\-]*?\s*?(sm|nm)[0-9]{7,8}/o ){
			next if $data =~ m{font color}o;
			
			chomp $data;
			$data =~ s/^[\s　]+//o;
			$data =~ s/[\s　]+$//o;
			push @comment, $data
				if length $data > 5;
			next;
		}
		
		$data =~ s/^\s+//o;
		
		# まず空白で切ってみる
		my ($n, $title) = split /[\s\t　]+/o, $data, 2;
		
		# 初期のログには空白で区切られていないものがあるので特別に処理する
		if( $n !~ /^(sm|nm)[0-9]{7,8}$/o ){
			($n, $title) = unpack "A9 A*", $data;
		}
		
		# DB からゲット
		my $v;
		if( ($v) = $schema->resultset('Video')->search( { vid => $n } )->slice( 0, 1 ) ){
			( my $vid = $n ) =~ s/^(sm|nm)//o;
			my $pname = join q{　}, grep { $_ ne '' } split ':', Encode::decode_utf8( $v->pnames );
			
			push @v, {
				id => $n,
				vid => $vid,
				title => Encode::decode_utf8( $v->title ),
				pnames => $pname,
				length => $v->length,
			};
		}
		else{
			warn "not found: $n";
			push @v, undef;
		}
	}
	
	# 合計時間を計算
	my $total = 0;
	for my $v( @v ){
		if( not defined $v ){
			$total  = 0;
			last;
		}
		my ($min, $sec) = split /:/o, $v->{length};
		$total += $min * 60;
		$total += $sec;
	}
	
	# 合計を文字列に直す
	my $total_str;
	if( $total == 0 ){
		$total_str = "??:??";
	}
	else{
		my $min = int( ( $total + 0.5 ) / 60 );
		my $sec = $total - ( $min * 60 );
		$total_str = sprintf "%02d:%02d", $min, $sec;
	}
	
	# set
	push @{ $stash->{result} }, {
		no => $no,
		name => $name,
		total_str => $total_str,
		comment => [ @comment ],
		video => [ @v ],
	};
}

# out
my $template = &create_template;

$template->process( $template_file, $stash, $html_file, binmode => ':utf8' )
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

__END__

printf STDERR "ignore: %d videos\n", scalar keys %{ $ignore };

my @video_all;
for my $v( sort { $video->{$b}->{num} <=> $video->{$a}->{num} || $video->{$a}->{id} <=> $video->{$b}->{id} } keys %{ $video } ){
	# 再生数が０なら飛ばそう
	next if $video->{$v}->{num} < 1;
	
	# ジングルは飛ばそう
	next if scalar( first { $v eq $_ } @jingle );
	
	# 告知動画なども飛ばそう
	next if scalar( first { $v eq $_ } @ignore );
	
	# すでに削除されているものを飛ばす
	next if first { $v eq $_ } @{ $Mikunopop::VideoInfo::Deleted };
	
	# その他おかしいものは飛ばす
	next if not defined $video->{$v}->{num};
	next if $video->{$v}->{num} eq '';
	
	my $d = {
		id => $v,    # sm1234567
		vid => $video->{$v}->{id},    # 1234567
		title => scalar( $video->{$v}->{title} || q/不明/ ),
		view => $video->{$v}->{num},    # 再生数
	};
	
	# all
	push @video_all, $d;
}

# count.json
{
	my $list;
	for my $v( @video_all ){
		$list->{ $v->{id} } = $v->{view};
	}
	
	require JSON::Syck;
	require DateTime::Format::Mail;
	
	# 最終更新日付を入れておく
	my $json = sprintf "// %s\n", DateTime::Format::Mail->format_datetime( DateTime->now( time_zone => 'Asia/Tokyo' ) );
	$json .= JSON::Syck::Dump( $list );
	
	my $fh = file( $json_file )->openw or die $!;
	$fh->print( $json );
	$fh->close;
}

# count.db
{
	my $fh = file( $db_file )->openw or die $!;
	$fh->print( YAML::Syck::Dump( [ @video_all ] ) );
	$fh->close;
}

# all tsv
{
	my $csv = Text::CSV_XS->new( { binary => 1 } );
	my @csv;
	for my $v( @video_all ){
		$csv->combine( map { Encode::encode('sjis', $_) } @{$v}{qw(view vid title)} );
		push @csv, $csv->string;
	}

	my $fh = file( $csv_file )->openw or die $!;
	$fh->print( Compress::Zlib::memGzip( join "\r\n", @csv ) );
	$fh->close;
}

exit 0;

__END__
