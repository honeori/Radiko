use strict;
use warnings;
use Test::More;
use Reserve;
use LWP::Simple;

subtest 'correct use' => sub {
  {
    my $obj = Reserve->new;
    ok $obj->getXml('http://google.co.jp');
  }
};

subtest 'incorrect use' => sub {
  {
    my $obj = Reserve->new;
    ok !$obj->getXml('hhffttp://google.co.jp');
  }
};
done_testing;
