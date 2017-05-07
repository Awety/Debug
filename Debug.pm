package Debug;

=head1 NAME

Debug - Perl module enabling one to handle the moment
when some variables get destroyed

=head1 VERSION

1.00000

=head1 SYNOPSIS

use Debug;

{
  # opened scope
  my $x = 33;
  Debug::blesser JustX => \$x;

}

# DESTROYED: JustX (created 2016-10-21 23:23:50)

=head1 DESCRIPTION

This module can be useful for debugging memleaks
in your application: if you create variables and leave
them as closures to anonymous subroutines hoping they
would be destroyed one day. So to be sure the variable
has been garbage collected this modules allows you to
get a warn to stderr with it's name and creation time
exaclty at the moment the variable has got destoryed.

=head1 USAGE

B<Debug::blesser($sig, $ref)> function gets two arguments:
$sig is a signature for variable to be displayed when the
destroy-message appears and $ref is a reference to that
variable.

The function returs the reference it has been passed to
which is useful to embedd that function into 'chain'
constructions (see L</EXAMPLES> section).

Create a variable like you always do but with calling
it B<blesser()> with any specified name:

my $hash =
    Debug::blesser Name => {};

Then some code goes with $hash where $hash should get
destroyed somewhere at the end.

Finaly when it actually gets destoyed the message to STDERR
would be produced declaring that your variable was garbage
collected. So it allows you to somehow 'mark' your variable
to be logged when all the references to it have gone away.

=head1 EXAMPLES

Idiomatic use cases are the following (very useful that
B<blesser()> function returns the reference it was passed):

my $complex_struct->{substruct} =
    Debug::blesser SubStruct => { foo => bar  };

my $cb; $cb = Debug::blesser CallBack => sub {
    ...
}

my $num = 42;
Debug::blesser universe_const => $num;

=head1 AUTHOR

Created by Pavel Limorenko <pavel@limorenko.com>

This program is free software; you may redistribute or modify it (or both)
under the same terms as perl.

=cut

use strict;
use warnings;

use Carp  qw(croak);
use POSIX qw(strftime);
use Scalar::Util qw(blessed);

our %MESSAGES;

sub blesser ($$) {
    my ($name, $ref) = @_;

    croak "Not a reference passed to blesser()"
        unless ref $ref
    ;
    croak "Already blessed reference: create DESTROY method by yourself"
        if blessed($ref)
    ;

    bless($ref, __PACKAGE__);

    my @caller    = caller();
    my $created   = strftime( "%F %H:%M:%S", localtime);
    my $namespace = "$ref";
    my $message   = "DESTROYED: $name (created $created at @caller)";

    $MESSAGES{$namespace} = $message;

    return $ref;
}

sub DESTROY {
    my $ref       = shift;
    my $namespace = "$ref";

    warn delete( $MESSAGES{$namespace} ) . "\n";
}

1;
