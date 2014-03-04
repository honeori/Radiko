package Reserve;
#使い方予定
#my $obj = Radiko::Api->new('JP13');
#my $LIST = qw(西川貴教 田村ゆかり);
#$obj->getTodayList($LIST);
#my $cronFile = $obj->convertToCron();
#みたいな感じ

use strict;
use LWP::Simple qw(get);
use HTML::TreeBuilder;

my $RADIKO_API = {
  today =>'http://radiko.jp/v2/api/program/today',
  tommorow => 'http://radiko.jp/v2/api/program/today',
};

sub new {
  my $class = shift;
  my $obj = {@_};
  bless $obj, $class;
}

sub _getShowFromWords {
  my $this = shift;
  my $mode = 'tommorow';
  my @wordList = @_;
  my $uri = URI->new($RADIKO_API->{$mode});
  $uri->query_form(
      area_id => $this->{area_id},
  );
  my $content = get $uri;
  my $tree = HTML::TreeBuilder->new;
  $tree->parse($content);
  $tree->eof;

#foreach my $title ($tree->find('title')) {
foreach my $title ($tree->find('prog')->find('title')) {
  #$title->dump;
#    print $title->as_text;
    print $title->as_HTML;
    print "\n";
  }
  foreach my $station ($tree->find('station')) {
    print $station->attr('id')->as_HTML, "\n";
  }

#foreach my $station ($tree->look_down("id", "TBS")) {
#      print $station->as_HTML;
#  }
#
#  foreach my $station ($tree->find('prog')) {
#    print "hoge\n";
#    print $station->attr('ft'), "\n";
#  }
#
#  tree->delete;

}

sub getTodayShowFromWords {
  my $this = shift;
  my $wordList = @_;
  return &_getShowFromWords($this, 'today', $wordList);
}

sub getTommorowShowFromWords {
  my $this = shift;
  my $wordList = @_;
  return &_getShowFromWords($this, 'tommorow', $wordList);
}

1;
