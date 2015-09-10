#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Record');
};

{
    my $obj = new Record;
    isa_ok $obj, 'Record', 'simple new';
}

done_testing;

