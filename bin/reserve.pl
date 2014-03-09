#!/usr/bin/perl 
use strict;
use warnings;
use LWP::Simple qw(get);
use XML::TreeBuilder;
use Data::Dumper;
use Encode qw{decode is_utf8};
binmode(STDOUT, ":utf8");

#TODO
#ファイル分割
#レスポンスコード確認
#超A&G

my %RADIKO_API = (
  today =>'http://radiko.jp/v2/api/program/today',
  tomorrow => 'http://radiko.jp/v2/api/program/tomorrow',
  weekly =>'http://radiko.jp/v2/api/program/station/weekly',
);

my $RESERVE_LIST_FILE = 'reserveList.data';
my $AREA_ID = 'JP13';
my $CRON_FILE = '_cron.txt';


my $content = getTodayContent($AREA_ID);
#my $content = getWeeklyContent('TBS');
my $tree = XML::TreeBuilder->new;
$tree->parse($content);
$tree->eof;
#print $content;

my @reserveList = getReserveWords();

my @cronList;
foreach my $station($tree->find('station')) {
  foreach my $prog ($station->find('prog')) {
    my $progRef;
    my $text = $prog->as_text;
    #print $text, "\n";
    foreach my $regExp(@reserveList) {
      if($text =~ /($regExp)/) {
        my $keyword = $1;
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
        $progRef->{station} = $station->attr('id');
        $progRef->{keyword} = $keyword;
        #foreach my $key(keys %$progRef) {
        #  print "$key:", $progRef->{$key}, "\n";
        #}
        #print "title\t", $progRef->{title}, "\n";
        print getCronFromProgRef($progRef), "\n";
        push @cronList, getCronFromProgRef($progRef);
        last;
      }
    }
  }
}

addCron(@cronList);

sub _getContent {
  my $uri = shift;
  return get $uri;
}

sub getTodayContent {
  my $area_id = shift;
  my $uri = URI->new($RADIKO_API{today});
  $uri->query_form(
    area_id => $area_id,
  );
  return _getContent $uri;
}

sub getTommorowContent {
  my $area_id = shift;
  my $uri = URI->new($RADIKO_API{tomorrow});
  $uri->query_form(
    area_id => $area_id,
  );
  return _getContent $uri;
}

sub getWeeklyContent {
  my $station = shift;
  my $uri = URI->new($RADIKO_API{weekly});
  $uri->query_form(
    station_id=>$station,
  );
  return _getContent $uri;
}

sub addCron {
  my @cronLines = @_;
  system 'crontab -l > '. $CRON_FILE;
  open my $fh, '>>', $CRON_FILE or die"can't open $CRON_FILE:$!";
  print $fh '#begin radiko autoReserve', "\n";
  foreach my $line (@cronLines) {
    print $fh $line, "\n";
  }
  print $fh '#end radiko autoReserve', "\n";
  unlink $CRON_FILE;
}

sub getReserveWords {
  my @reserveList;
  open my $fh, '<', $RESERVE_LIST_FILE or die "can't open $RESERVE_LIST_FILE:$!";
  while(<$fh>) {
    chomp;
    push @reserveList, $_;
  }

  @reserveList = map{decode('utf8', $_);} @reserveList;
}

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

#59 2 * * 3 /home/stlange/script/radiko/radiko.sh LFR 122 moto >mylog/log.txt 2>&1
sub getCronFromProgRef {
  my $prog = shift;
  my $minute = $prog->{minute};
  my $hour = $prog->{hour};
  my $day = $prog->{day};
  my $month = $prog->{month};
  my $duration = $prog->{length};
  $duration /= 60;
  $duration += 1; #一応後ろ１分余分に録音
  #TODO 前一分もとりたい
  my $str = "$minute\t$hour\t$day\t$month\t*\t";
  $str .= '/home/stlange/script/radiko/radiko.sh';
  $str .= "\t". $prog->{station}. "\t$duration\t". 'autoReserve'. "\t". '>mylog/log.txt 2>&1';
  return $str;
}

