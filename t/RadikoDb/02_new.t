#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Warn;
use RadikoDb;


subtest 'just new' => sub {
	{
		my $obj = RadikoDb->new;
		isa_ok $obj, 'RadikoDb', 'no arg';
	}

	{
		my $dbName = 'test.db';
		my $obj = RadikoDb->new({
				dbName => $dbName,
				debug => 1,
			});
		isa_ok $obj, 'RadikoDb';
	}
	{
		my $obj = RadikoDb->new({
				debug => 1,
			});
		isa_ok $obj, 'RadikoDb', 'debug on';
	}
	done_testing;
};

subtest '' => sub {
	{
		my $dbName = 'test.db';
		my $obj = RadikoDb->new({
				dbName => $dbName,
			});
		my $result = 0;
		if(-e $dbName) {
			$result = 1;
		}
		ok $result;
		unlink $dbName;
	}
	{
		my $dbName = 'test.db';
		my $obj = RadikoDb->new({
				dbName => $dbName,
				debug => 1,
			});
		my $result = 0;
		if(! -e $dbName) {
			$result = 1;
		}
		ok $result;
	}
};

done_testing;
