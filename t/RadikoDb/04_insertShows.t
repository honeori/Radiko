#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Warn;
use RadikoDb;

subtest 'fail to insertShows' => sub {
  unlink 'radiko.db';
  my $db = RadikoDb->new;
    my $show = {};
    is ($db->insertShows($show), undef);

  done_testing;
};

subtest 'success to insertShows' => sub {
  unlink 'radiko.db';
  my $db = RadikoDb->new;
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

  done_testing;
};

subtest 'success to many object insertShows' => sub {
  unlink 'radiko.db';
  my $recordCount = 10;
  my $shows = [];
  my $db = RadikoDb->new;
  my $show = {
    title =>'title',
    date => 'date',
    station => 'station',
    keyword => 'keyword',
    path => 'path',
  };
  foreach my $i (1...$recordCount) {
    push @$shows, $show;
  }
  $db->insertShows($shows);
  my $count = 0;
  my $sth = $db->selectShowAll;
  while(my $row = $sth->fetchrow_hash) {
    $count++
  }
  is ($count, $recordCount);

  done_testing;
};

done_testing;
