#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use ReserveList;

subtest 'no config' => sub {
	my $obj = ReserveList->new;
	is $obj, undef;
};

subtest 'set config' => sub {
	my $config_file = '__test_config.ini';
	open my $fh, '>', $config_file or die;
	my $obj = ReserveList->new($config_file);
	isa_ok $obj, 'ReserveList';

	unlink $config_file;
};


done_testing;

