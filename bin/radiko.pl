#!/usr/bin/perl
#使い方 実行した時間から32分間録音した音声をrafurafuというディレクトリにrafurafu_20140426.mp3みたいに保存
#radiko.pl TBS 32 rafurafu

use strict;
use warnings;

#録音時間（秒）
#my $duration = 32 * 60;
#my $duration = 1;
my $duration = $ARGV[0] * 60;
#保存する番組名
#my $showName = "rafurafu";
my $showName = $ARGV[1];

my $dirName = '/home/stlange/script/radiko';
my $rtmpCommand = q{/usr/local/bin/rtmpdump};
my $ffmpegCommand = q{/usr/local/bin/ffmpeg};
my $tempFile = q{_a_and_g_out.flv};
$tempFile = $showName . $tempFile;

my $dateStr = getDateString();
#録音開始まではスクリプト実行からすぐに行う
my $execRtmpCommand = qq{
  $rtmpCommand --rtmp rtmpe://fms2.uniqueradio.jp/ --playpath aandg2 --app ?rtmp://fms-base1.mitene.ad.jp/agqr/ --stop $duration --live -o $tempFile
};
my $rtmpResult = `$execRtmpCommand`;

#ここからはゆっくりでOK
$dirName .= "/$showName";
my $fileName = "$dirName/$showName". "_$dateStr.mp3";
if(! -e $dirName) {
  mkdir $dirName;
}
my $execFfmpegCommand = qq{$ffmpegCommand -y -i $tempFile -acodec mp3 $fileName};
my $ffmpegResult = `$execFfmpegCommand`;

#print "dir :$dirName\n";
#print "date:$dateStr\n";
#print "file :$fileName\n";
if(defined($rtmpResult)) {
  print $rtmpResult;
  print "\n";
}
if(defined($ffmpegResult)) {
  print $ffmpegResult;
  print "\n";
}

unlink $tempFile;

  
#/usr/local/bin/ffmpeg -y -i "$home/${1}_${date}" -acodec mp3 "$home/${1}_${date}.mp3"
#rtmpdump --rtmp rtmpe://fms2.uniqueradio.jp/ --playpath aandg2 --app ?rtmp://fms-base1.mitene.ad.jp/agqr/ --stop 10 --live -o test.flv

#現在の日付を文字列で取得
sub getDateString {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year += 1900;
  $mon += 1;
  my $rtn = sprintf('%04d-%02d-%02d-%02d:%02d', $year, $mon, $mday, $hour, $min);
  return $rtn;
}
