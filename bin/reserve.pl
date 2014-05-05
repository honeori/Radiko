#!/usr/bin/perl 
use strict;
use warnings;
#use LWP::Simple qw(get);
use LWP::UserAgent;
use XML::TreeBuilder;
use Data::Dumper;
use Encode qw{decode is_utf8 encode};
use FindBin;
use File::Spec; 
use lib "$FindBin::RealBin/../lib";
use File::Basename qw{dirname};


use RadikoDb;
binmode(STDOUT, ":utf8");

#TODO
#ファイル分割
#超A&G

my %RADIKO_API = (
  today =>'http://radiko.jp/v2/api/program/today',
  tomorrow => 'http://radiko.jp/v2/api/program/tomorrow',
  weekly =>'http://radiko.jp/v2/api/program/station/weekly',
);

my $ON_DEBUG = 1;
#my $ON_DEBUG = 0;

my $ON_CHECK_DATA = 1;
#my $ON_CHECK_DATA = 0;

my $RESERVE_LIST_FILE = 'reserveList.data';
my $CRON_FILE = '_cron.txt';
my $RESERVE_LAST_DATE = '_lastdate.txt';
my $ABS_BASE = dirname $0;
$ABS_BASE .= '/';
$RESERVE_LIST_FILE = $ABS_BASE . $RESERVE_LIST_FILE;
$CRON_FILE= $ABS_BASE . $CRON_FILE;
$RESERVE_LAST_DATE = $ABS_BASE . ($RESERVE_LAST_DATE);
my $AREA_ID = 'JP13';

main();

sub main {
  my $content = getTodayContent($AREA_ID);
  my $tree = XML::TreeBuilder->new;

  $tree->parse($content);
  $tree->eof;

  my $date = $tree->find('date')->as_text;
  $date =~ /^(\d{4})(\d{2})(\d{2})$/g;
  $date = "$1-$2-$3 00:00:00";

  if($ON_CHECK_DATA) {
    if(!checkDate($date)) {
      print "$date shows is reserved";
      exit(0);
    }
  }

  my $DB = RadikoDb->new({
    debug => 1,
  });
  if(!$DB->hasRecordedInLineup($date)) {
    print "not have\n";
    $DB->insertLineup($content, $date);
  } else {
    print "have\n";
  }

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
          print "title\t", $progRef->{title}, "\n";
          print "keyword\t", $progRef->{keyword}, "\n";
          #print getCronFromProgRef($progRef), "\n";
          push @cronList, getCronFromProgRef($progRef);
          if($ON_DEBUG) {
            print $progRef->{title}
          }
          last;
        }
      }
    }
  }

  createCronFile($date,\@cronList);
  system "crontab $CRON_FILE";
  {
    open my $fh, '>', $RESERVE_LAST_DATE or die "can't open $RESERVE_LAST_DATE :$!";
    print $fh $date;
  }
}

sub checkDate {
  #ex $date = "$1-$2-$3 00:00:00";
  my $date = shift;
  if(!defined($date)) {
    return 0;
  }
  my $lastDate = getLastDate();

  my $parseDate = sub {
    my $date = shift;
    my ($year, $month, $day);
    if($date =~ /(\d{4})-(\d{2})-(\d{2})/) {
      $year = $1;
      $month = $2;
      $day = $3;
    } elsif($date =~ /(\d{4})(\d{2})(\d{2})/) {
      $year = $1;
      $month = $2;
      $day = $3;
    } else {
      die '$date error';
    }
    return ($year, $month, $day);
  };
  my ($year, $month, $day) = $parseDate->($date);
  my $lastDateHash = {};

  if(!defined($lastDate)) {
    return 1;
  } else {
    ($lastDateHash->{year}, $lastDateHash->{month}, $lastDateHash->{day})
      = $parseDate->($lastDate);
  }
  use Date::Calc qw(Date_to_Days);
  if($ON_DEBUG) {
    print "\n";
    print "date: $date\t", Date_to_Days($lastDateHash->{year}, $lastDateHash->{month}, $lastDateHash->{day}), "\n" ;
    print "lastdate: $lastDate\t", Date_to_Days($year, $month, $day), "\n";
  }

  return Date_to_Days($lastDateHash->{year}, $lastDateHash->{month}, $lastDateHash->{day} ) 
          < Date_to_Days($year, $month, $day);
}

sub getLastDate {
  open my $fh, '<', $RESERVE_LAST_DATE or die qq{ can't open $RESERVE_LAST_DATE:$!};
  my $lastDate;
  while(<$fh>) {
    chomp;
    $lastDate = $_;
  }
  return $lastDate;
}


sub _getContent {
  my $MAX_RETRY_COUNT = 3;
  my $uri = shift;
  my $ua = LWP::UserAgent->new();
  my $response;
  foreach my $i (1...$MAX_RETRY_COUNT) {
    $response = $ua->get($uri);
    if(defined($response) && $response->is_success) {
      print $response->status_line;
      last;
    } else {
      print $response->status_line, "\n";
      print "wait a second\n";
      sleep 1;
      if($i == $MAX_RETRY_COUNT) {
        return undef;
      }
    }
  }
  return $response->content;
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

sub createCronFile {
  my $date = shift;
  my $lines = shift;
  my @cronLines = @$lines;
  system 'crontab -l > '. $CRON_FILE;
  open my $fh, '>>', $CRON_FILE or die"can't open $CRON_FILE:$!";
  print $fh '#begin radiko autoReserve '.$date, "\n";
  foreach my $line (@cronLines) {
    print $fh $line, "\n";
  }
  print $fh '#end radiko autoReserve', "\n";
  #unlink $CRON_FILE;
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
  my $title = $prog->{title};
  $duration /= 60;
  $duration += 1; #一応後ろ１分余分に録音
  #TODO 前一分もとりたい
  my $str = "$minute\t$hour\t$day\t$month\t*\t";
  $str .= '/home/stlange/script/radiko/radiko.sh';
  #$str .= "\t". $prog->{station}. "\t$duration\t". 'autoReserve'. "\t". '>mylog/log.txt 2>&1';
  $str .= "\t". $prog->{station}. "\t$duration\t". $title. "\t". '>mylog/log.txt 2>&1';
  return $str;
}

