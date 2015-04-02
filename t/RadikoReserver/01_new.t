#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use RadikoReserver;

subtest 'RadikoReserver' => sub {
	subtest '#new' => sub {
		my $obj = RadikoReserver->new;
		isa_ok $obj, 'RadikoReserver';
	};
};

done_testing;

