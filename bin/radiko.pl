#!/usr/bin/perl
#使い方 実行した時間から32分間録音した音声をrafurafuというディレクトリにrafurafu_20140426.mp3みたいに保存
#radiko.pl TBS 32 rafurafu

use strict;
use warnings;

use lib '../lib';

use Record;

main();

sub main {
    my ($station, $duration, $fileName) = @ARGV;

    if(!defined($fileName)) {
        printUsage();
    }

    my $recorder = new Record({
        conf => '../record.ini',
    });

    $duration *= 60; #convert sec to minute.
    $recorder->start('aaa.flv', $station, $duration);
    $recorder->convert('aaa.flv', $fileName);
}

sub printUsage {
    print STDERR <<'EOF';
Usage:
    ./radiko.pl 'A&G' 32 rafurafu.mp3
EOF
}

