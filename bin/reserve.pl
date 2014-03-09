#!/usr/bin/perl 
use strict;
use warnings;
use LWP::Simple qw(get);
use XML::TreeBuilder;
use Data::Dumper;
use Encode qw{decode is_utf8};
binmode(STDOUT, ":utf8");

my %RADIKO_API = (
  today =>'http://radiko.jp/v2/api/program/today',
  tommorow => 'http://radiko.jp/v2/api/program/today',
);


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
sub _getShowFromWords {
  my $this = shift;
  my $mode = 'tommorow';
  my @wordList = @_;
}

my $mode = 'today';
my $uri = URI->new($RADIKO_API{$mode});
$uri->query_form(
      area_id => 'JP13',
);
my $content = get $uri;
my $tree = XML::TreeBuilder->new;
$tree->parse($content);
$tree->eof;
#print $content;

#foreach my $title($tree->find('title')) {
#print $title->as_text;
##print $title->as_HTML;
#print "\n";
#}
#foreach my $station ($tree->look_down("id", "TBS")) {
#  print $station->attr('id');
#  print "\n";
#}

#my @RESERVE_LIST = qw{西川　森};
#my @RESERVE_LIST = qw{fax br};
my @RESERVE_LIST = ("天気予報");
@RESERVE_LIST = map{decode('utf8', $_);} @RESERVE_LIST;
#my $regExp = '('. join('|', @RESERVE_LIST). ')'; 
#my $regExp = join( '|', @RESERVE_LIST);
my $regExp;
foreach my $word (@RESERVE_LIST) {
  if(!defined($regExp)) {
    $regExp = '('.$word.')';
  } else {
    $regExp .= '|'. '('.$word.')';
  }
}


print $regExp, "\n";

my $progRef;
foreach my $prog ($tree->find('prog')) {
  my $text = $prog->as_text;
  #print $text, "\n";
  if($text =~ /$regExp/) {
    my ($year, $month, $day, $hour, $minute, $second) = 
      parseDate($prog->attr('ft'));
    $progRef->{title} = $prog->find('title')->as_text;
    $progRef->{year} = $year;
    $progRef->{month} = $month;
    $progRef->{day} = $day;
    $progRef->{hour} = $hour;
    $progRef->{minute} = $minute;
    $progRef->{second} = $second;
    $progRef->{length} = $prog->attr('dur');
    $progRef->{url} = $prog->find('url')->as_text;
    $progRef->{keyword} = $1;
    foreach my $key(keys %$progRef) {
      print "$key:", $progRef->{$key}, "\n";
    }
    print "\n";
  }
}

#59 2 * * 3 /home/stlange/script/radiko/radiko.sh LFR 122 moto >mylog/log.txt 2>&1

sub parseDate {
  my $str = shift;
  #20140309050000
  if($str =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/) {
    return ($1, $2, $3, $4, $5, $6);
    #year, month, day, hour ,minute,second
  } else {
    print STDERR "parse error";
    return undef;
  }
}

