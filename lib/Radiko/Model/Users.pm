package Radiko::Model::Users;

use strict;
use warnings;

my $USERS = {
    joel    => 'aaa',
};

sub new {
    bless {}, shift;
}

sub check {
    my $this = shift;
    my ($user, $pass) = @_;

    if($USERS->{$user} && $USERS->{$user} eq $pass) {
        return 1;
    } else {
        return undef;
    }
}

1;
