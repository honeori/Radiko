#!/usr/bin/perl

use strict;
use warnings;

my $duration = 2;
my $showName = "rafurafu";

my $rtmpCommand = q{/usr/local/bin/rtmpdump};
my $ffmpegCommand = q{/usr/local/bin/ffmpeg};
my $tempFile = q{_out.flv};

my $execRtmpCommand = qq{
  $rtmpCommand --rtmp rtmpe://fms2.uniqueradio.jp/ --playpath aandg2 --app ?rtmp://fms-base1.mitene.ad.jp/agqr/ --stop $duration --live -o $tempFile};
my $rtmpResult = `$execRtmpCommand`;

my $execFfmpeCommand = qq{
  $ffmpegCommand -y -i $tempFile -acodec mp3 hoge.mp3};
my $ffmpegResult = `$execFfmpeCommand`;

print $ffmpegResult;

  
#/usr/local/bin/ffmpeg -y -i "$home/${1}_${date}" -acodec mp3 "$home/${1}_${date}.mp3"
#rtmpdump --rtmp rtmpe://fms2.uniqueradio.jp/ --playpath aandg2 --app ?rtmp://fms-base1.mitene.ad.jp/agqr/ --stop 10 --live -o test.flv
