use strict;
use warnings;
use Test::More;
use Reserve;

subtest 'correct use' => sub {
  {
    my $obj = Reserve->new(area_id=>'JP13');
    ok $obj->getTodayShowList;
  }

  {
    my $obj = Reserve->new;
    $obj->setAreaId('JP14');
    ok $obj->getTodayShowList;
  }
};

subtest 'incorrect use' => sub {
  my $obj = Reserve->new;
  ok !$obj->getTodayShowList;
};
done_testing;
