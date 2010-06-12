# 

use v5.10;
use strict;
use warnings;

use Plack::App::PSGIBin;
use Plack::Builder;

use Path::Class qw(dir file);
use BSD::Resource qw(RLIMIT_VMEM);

use IO::File;
use Fcntl qw(:flock);

use utf8;

my $project_dir = dir("/web", "mikunopop" );
my $htdocs_dir = dir( $project_dir, "htdocs" );
my $app_dir = dir( $project_dir, "app" );

# resource limit
BSD::Resource::setrlimit(RLIMIT_VMEM, 80 * 1000 ** 2, 100 * 1000 ** 2);

# log
my $log_file = file( $project_dir, "logs", "backend.log" );
my $logger = sub {
	my $fh = IO::File->new( $log_file, O_CREAT|O_WRONLY|O_APPEND ) or die $!;
	flock $fh, LOCK_EX;    # get lock for infinity
	seek $fh, 0, LOCK_EX;
	print {$fh} @_;
	flock $fh, LOCK_UN;    # release lock
	$fh->close;
};

# app
my $app = Plack::App::PSGIBin->new( root => $app_dir )->to_app;

builder {
	# load Plack::Middleware::**
	enable 'AccessLog', format => 'combined', logger => $logger;
	enable 'ConditionalGET';
	enable 'HTTPExceptions';
	enable 'ErrorDocument',
		500 => '/error/500.html',
		404 => '/error/404.html',
		subrequest => 1;
#	enable 'Runtime';
#	enable 'Head';
#	enable 'XFramework', framework => "Fumi2";
	enable 'Header',
		set => [ Server => 'PSGI-compatible Server' ];

#	enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
#		'ReverseProxy';
	enable 'ReverseProxy';

#	enable 'LogDispatch', logger => Log::Dispatch::Config->instance;
	
	# for static contents, mainly for devel env.
#	enable_if { $_[0]->{PATH_INFO} =~ q{^/static/\d+/} } 'Header', set=> [ 'Expires' => 'Tue, 31 Dec 2019 23:59:59 GMT' ];
	enable 'Plack::Middleware::Static', path => qw{^/(img|css|js|error|doc)/}, root => $htdocs_dir->stringify;
	enable 'Plack::Middleware::Static', path => qw{^/(?:favicon\.(ico|png)|robots\.txt)$}, root => $htdocs_dir->stringify;

	mount "/" => $app;
};

__END__

