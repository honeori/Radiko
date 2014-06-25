#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Warn;
use RadikoDb;

subtest 'fail to insertShows' => sub {
	my $db = RadikoDb->new({
		debug => 1,
	});
	my $show = {};
	is ($db->insertShows($show), undef);

	done_testing;
};

subtest 'success to insertShows' => sub {
	my $db = RadikoDb->new({
		debug => 1,
	});
	my $shows = [];
	my $show = {
		title =>'title',
		date => 'date',
		station => 'station',
		keyword => 'keyword',
		path => 'path',
	};
	push @$shows, $show;
	ok ($db->insertShows($shows));
	my $DB = $db->getDB;
	my $sth = $DB->prepare(q{
		SELECT * FROM show_list
	});
	$sth->execute();
	my $count = 0;
	while(my $data = $sth->fetchrow_hashref) {
		++$count;
	}
	is($count, 1);

	done_testing;
};

subtest 'success to many object insertShows' => sub {
	my $db = RadikoDb->new({
		debug => 1,
	});
	my $recordCount = 10;
	my $shows = [];
	map {push @$shows, {
		title =>'title',
		date => 'date',
		station => 'station',
		keyword => 'keyword',
		path => 'path',
	}} 1...$recordCount;
	$db->insertShows($shows);
	my $DB = $db->getDB;
	my $sth = $DB->prepare(q{
		SELECT * FROM show_list
	});
	$sth->execute();
	my $count = 0;
	#なぜか$sth->rows では取得できない
	while(my $data = $sth->fetchrow_hashref) {
		++$count;
	}
	is($count, $recordCount);

	done_testing;
};

done_testing;
