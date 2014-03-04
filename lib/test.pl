#!/usr/bin/perl

use strict;
use warnings;

use Reserve;

binmode(STDOUT, ":utf8");
my $obj = Reserve->new(area_id =>'JP13');
$obj->getTodayShowFromWords(qw(a i u));
