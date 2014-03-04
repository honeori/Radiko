use strict;
use warnings;
use Test::More;
use Test::Warn;
use Reserve;


subtest 'no args' => sub {
  my $obj = Reserve->new;
  isa_ok $obj, 'Reserve';
};

subtest 'area => JP13' => sub {
  my $obj = Reserve->new(area_id =>'JP13');
  isa_ok $obj, 'Reserve';
};

subtest 'area => JP1' => sub {
  my $obj = Reserve->new(area_id=>'JP1');
  isa_ok $obj, 'Reserve';
};

subtest 'area => JP47' => sub {
  my $obj = Reserve->new(area_id=>'JP47');
  isa_ok $obj, 'Reserve';
};

warning_is{my $obj = Reserve->new(area_id=>'JP48')} "invalid area_id", "invalid area_id";
warning_is{my $obj = Reserve->new(area_id=>'haaaa')} "invalid area_id", "awful area_id";

done_testing;
