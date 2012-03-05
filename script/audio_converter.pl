#!/usr/bin/perl --
# ニコ動から動画を落として１０秒切り出してプレビュー用 mp3 ファイルを作る
# nicovideo-dl, ffmpeg, Xcode (af*), vorbis-tools, sox, lame, cws2fws.c

use strict;
use warnings;
use Path::Class qw(file dir);
use File::Temp;
use Try::Tiny;
use File::Glob;
use Getopt::Std ();
use JSON::Syck;
use LWP::Simple;

use utf8;

chdir "/tmp";

my $save_dir = dir("/Volumes/BOX2/Music/MikunoMP3");

# getopt
Getopt::Std::getopts 'fi:' => my $opt = {};
# -f: force
# -i: video id

my @video;
if( defined $opt->{i} and $opt->{i} ne '' ){
	@video = ( $opt->{i} );
}
else{
	my $json = JSON::Syck::Load( get("http://mikunopop.info/play/count.json") ) or die $!;
	@video = reverse sort { $json->{$a} <=> $json->{$b} } grep { /^(sm|nm|so)/o } keys %{ $json };
}

for my $video_id( @video ){
	try {
		&main( $video_id );
	} catch {
		warn $_;
	};
}

exit 0;

sub main {
	my $video_id = shift or return;

	# path
	( my $vid = $video_id ) =~ s{^(sm|nm|so)}{}o;
	my $first = int( $vid / 1000 / 1000 );
	my $second = int( ( $vid - ( $first * 1000 ** 2 )  ) / 1000 );
	
	# prep
	my $output_file_mp3 = file( $save_dir, &id2path( $video_id ) . ".mp3" );
	my $output_file_ogg = file( $save_dir, &id2path( $video_id ) . ".ogg" );
	$output_file_mp3->parent->mkpath
		if not -e $output_file_mp3->parent;
	
	# check
	if( -e $output_file_mp3 and not defined $opt->{f} ){
#		printf STDERR "\talready exists.\n";
		return;
	}
	
	printf STDERR "=> %s\n", $video_id;
	
	# 
	my $file;
	do {
		my $cmd = sprintf "nicovideo-dl %s", $video_id;
		system( $cmd );
		
		for( File::Glob::bsd_glob( sprintf "%s.*", $video_id ) ){
			$file = $_;
		}
		if( not -e $file ){
			die "cannot get video ?";
		}
	};
	
	# 抽出
	my $input;
	do {
		my $cmd;
		if( $file =~ /flv$/o ){
			$input = "./input.mp3";
			$cmd = sprintf "ffmpeg -loglevel quiet -i %s -acodec copy %s", $file, $input;
		}
		elsif( $file =~ /mp4$/o ){
			$input = "./input.m4a";
			$cmd = sprintf "ffmpeg -loglevel quiet -i %s -acodec copy %s", $file, $input;
		}
		elsif( $file =~ /swf$/o ){
			# 圧縮形式をむりやり変換してみる
			my $file_before = sprintf "_%s", $file;
			rename $file, $file_before;
			
			do {
				my $cmd = sprintf "cws2fws %s %s", $file_before, $file;
				qx( $cmd );
				
				# fall back
				if( not -e $file ){
					$file = $file_before;
				}
			};
			
			$input = "./input.mp3";
			$cmd = sprintf "ffmpeg -loglevel quiet -i %s %s", $file, $input;
		}
		
		unlink $input if -e $input;
		qx( $cmd );
		
		my $st = file($input)->stat;
		if( $st->size < 10000 ){
			die "cannot extract mp3/m4a ?";
		}
	};
	
	my $input_file = file( $input );
	
	# 長さを取得しておく
	my $start = 30;
	do {
		my $cmd = sprintf "/usr/bin/afinfo %s", $input_file;
		my $result = qx( $cmd );
		
		for( split /\n/o, $result ){
			next if not /^estimated duration: ([\d\.]+)/o;
			my $len = int($1);
			if( $len < 30 ){
				$start = 10;
			}
			else{
				$start = $len - 60;
				$start = 30 if $start < 30;
			}
			last;
		}
		
		printf STDERR "start: %d sec\n", $start;
	};
	
	# まず手元の mp3/aac を aiff に変換しておく
	my $full_aif_file;
	do {
		# prep full_aif_file
		my ($fh, $filename) = File::Temp::tempfile( "temp_aif_XXXXXXXX", DIR => "/tmp", CLEANUP => 1, TMPDIR => 1 );
		$full_aif_file = file( $filename );
		
		# 
		my $cmd = sprintf "/usr/bin/afconvert -f AIFF -d BEI16 %s %s", $input_file, $full_aif_file;
		qx( $cmd );
		
		my $st = $full_aif_file->stat;
		if( $st->size < 10000 ){
			die "cannot convert full aif ?";
		}
	};
	
	# sox で短い wav を作成
	my $tmp_wav_file;
	do {
		# prep full_aif_file
		my ($fh, $filename) = File::Temp::tempfile( "temp_wav_XXXXXXXX", DIR => "/tmp", CLEANUP => 1, TMPDIR => 1 );
		$tmp_wav_file = file( $filename );
		
		# 長さ１０秒で切り出し、前後 0.4 秒ずつフェードさせる、ノーマライズもかける。
		my $cmd = sprintf "sox %s -c 1 -b 16 -t wav %s trim %d 10 rate 44.1k gain -n fade h 0.4 10 0.4", $full_aif_file, $tmp_wav_file, $start;
		qx( $cmd );
		
		my $st = $tmp_wav_file->stat;
		if( $st->size < 10000 ){
			die "cannot convert tmp wav ?";
		}
	};
	
	# mp3 に変換
	do {
		my $cmd = sprintf "lame --quiet -q 2 --preset cbr 56 %s %s", $tmp_wav_file, $output_file_mp3;
		qx( $cmd );
		
		my $st = $output_file_mp3->stat;
		if( $st->size < 10000 ){
			die "cannot convert result mp3 ?";
		}
	};
	
	# ogg に変換
	do {
		my $cmd = sprintf "oggenc -C 1 -b 56 -o %s %s", $output_file_ogg, $tmp_wav_file;
		qx( $cmd );
		
		my $st = $output_file_ogg->stat;
		if( $st->size < 10000 ){
			die "cannot convert result ogg ?";
		}
	};
	
	# cleanup
	unlink $input_file;
	unlink $file;
	unlink $full_aif_file;
	unlink $tmp_wav_file;
}

sub id2path {
	my $id = shift;
	
	( my $vid = $id ) =~ s{^(sm|nm|so)}{}o;
	
	my $first = sprintf "%03d", int( $vid / 1000 / 1000 );
	my $second = sprintf "%03d", int( ( $vid - ( $first * 1000 ** 2 )  ) / 1000 );
	
	return file( $first , $second, sprintf "%s", $id );
}

__END__
