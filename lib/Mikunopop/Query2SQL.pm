# only like mode

package Mikunopop::Query2SQL;

use Any::Moose;

use List::Util qw(first);
use List::MoreUtils qw(uniq);

use utf8;

has 'eliminate_num' => (
	is => 'rw',
	isa => 'Int',
	default => 5,
);

has 'query' => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

has 'column' => (
	is => 'rw',
	isa => 'ArrayRef[Str]',
);

has 'method' => (
	is => 'rw',
	isa => 'Str',
	default => "AND",
);

has 'quote_with_colon' => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

sub BUILD {
	my $self = shift;

	return $self->init;
}

sub init {
	my $self = shift;
	my $query = $self->query;
	
	my @word = $self->eliminate_query( $query );
	
	# set
	$self->{query} =  join ' ', @word;
	$self->{word} = [ @word ];

	return $self;
}

sub column {
	my $self = shift;
	my @column = @_;

	if( scalar @column > 0 ){
		$self->{column} = [ @column ];
	}

	return wantarray ? @{ $self->{column} } : $self->{column};
}

sub sql {
	my $self = shift;

	my $method = ( first { $self->method =~ /^$_$/i } qw(AND OR) ) || 'AND';

	my @query;
	for my $q( @{ $self->{word} } ){
		my @data;
		for my $c( @{ $self->{column} } ){
			if( $q =~ /^\-/o ){
				push @data, sprintf q|%s not like ?|, $c;
			}
			else{
				push @data, sprintf q|%s like ?|, $c;
			}
		}
		
		if( $q =~ /^\-/o ){
			push @query, sprintf "( %s )", join ' AND ', @data;
		}
		else{
			push @query, sprintf "( %s )", join ' OR ', @data;
		}
	}

	my $query = sprintf "( %s )", join " $method ", @query;

	return $query;
}

sub param {
	my $self = shift;

	my @param;
	for my $q( @{ $self->{word} } ){
		for my $column( @{ $self->{column} } ){
			if( $self->quote_with_colon ){
				push @param, sprintf q|%%:%s:%%|, $self->sanitize( $q );
			}
			else{
				push @param, sprintf q|%%%s%%|, $self->sanitize( $q );
			}
		}
	}

	return wantarray ? @param : [ @param ];
}

sub eliminate_query {
	my $self = shift;
	my $query = shift or return;

	# parse
	my @str = grep { $_  ne '' } split /[\s\t　]+/o, $query;

	# remove extra words
	@str = grep { ! /^(AND|OR)$/io } @str;

	# normalize
	@str = map { my $s = $_; $s =~ s/^[\-]+/-/go; $s }
		map { s/^[\+]+/+/go; $_ }
		@str;

	# uniq
	@str = uniq @str;

	# eliminate by max num
	@str = splice @str, 0, $self->eliminate_num;

	return wantarray
		? @str
		: join ' ', @str;    # stringify
}

sub sanitize {
	my $self = shift;
	my $str = shift;

	$str =~ s@[\!\"\#\$\%\&\'\(\)\-\=\^\~\\\|\{\}\[\]\+\*\<\>\?\.]@@go;    # "

	return $str;
}

1;

__END__
