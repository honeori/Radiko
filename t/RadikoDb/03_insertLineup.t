#!/usr/bin/perl 
use strict;
use warnings;
use Test::More;
use DateTime;
use RadikoDb;

subtest 'insertLineup' => sub {
	my $obj = RadikoDb->new({
			debug => 1,
	});
	my $lineup = q{<xml></xml>};
	my $dt = DateTime->now( time_zone =>'local' );

	$obj->insertLineup($lineup);
	my $date = $dt->strftime('%Y%m%d %H:%M:%S');

	my $DB = $obj->getDB;
	my $sth = $DB->prepare(q{
		SELECT xml,date FROM lineup WHERE date = ?
	});
	eval{
		$sth->execute($date);
	};

	my $result = $sth->fetchrow_hashref;
	my $resultXml = $result->{xml};
	my $resultDate= $result->{date};
	diag $resultXml;
	diag $resultDate;
	diag $sth->rows;

	is($lineup, $resultXml);
	is($resultDate, $date);
	done_testing;

};
subtest 'insertLineup with date' => sub {
	my $obj = RadikoDb->new({
			debug => 1,
	});
	my $lineup = q{<xml></xml>};
	my $dt = DateTime->now( time_zone =>'local' );
	my $date = $dt->strftime('%Y%m%d %H:%M:%S');

	$obj->insertLineup($lineup, $date);

	my $DB = $obj->getDB;

	my $sth = $DB->prepare(q{
		SELECT xml,date FROM lineup WHERE date = ?
		});
	eval{
		$sth->execute($date);
	};

	my $result = $sth->fetchrow_hashref;
	my $resultXml = $result->{xml};
	my $resultDate= $result->{date};
	diag $resultXml;
	diag $resultDate;
	diag $sth->rows;

	is($lineup, $resultXml);
	is($resultDate, $date);
	done_testing;
};


done_testing;

