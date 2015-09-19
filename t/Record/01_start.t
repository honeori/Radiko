#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Record;

use Config::Tiny;

subtest 'rec radiko' => sub {
    my $conf_file = 'radiko.ini.test';
    my $player_file = 'player.swf';
    my $config = new Config::Tiny;
    $config->{global}{workdir} = './testbase';
    $config->{global}{savedir} = './savedir';
    $config->{global}{debug} = 1;
    $config->{radiko}{player} = $player_file;
    $config->{radiko}{player_url} = 'http://radiko.jp/player/swf/player_3.0.0.01.swf';
    $config->{radiko}{auth1_url} = 'https://radiko.jp/v2/api/auth1_fms';
    $config->{radiko}{auth2_url} = 'https://radiko.jp/v2/api/auth2_fms';
    $config->{radiko}{url} = 'rtmpe://f-radiko.smartstream.ne.jp';
    $config->write($conf_file);

    my $recorder = new Record({
        conf => $conf_file,
    });

    my $base = $config->{global}{workdir};
    my $player_path = "$base/$player_file";
    ok -e $player_path, 'setup player file';
    my $player_file_type = `file $player_path`;
    like $player_file_type, qr/Macromedia Flash data/, 'check player file type';

    my $file = "test.flv";
    $recorder->start(
        $file,
        'LFR',
        1,
        'JP13',  #optionally
    );

    {
        my $size = -s "$base/$file";
        ok $size > 0, "rec ok $file";

        my $flv_file_type = `file $base/$file`;
        like $flv_file_type, qr/Macromedia Flash Video/, 'check flv file type';
    }

    my $savedir = $config->{global}{savedir};
    my $dest_file = 'test.mp3';

    $recorder->convert($file, $dest_file);

    ok -e "$savedir/$dest_file", 'convert ok';
    my $conv_file_type = `file $savedir/$dest_file`;

    like $conv_file_type, qr/MPEG ADTS/, 'check file type';


    system "cp testbase/proc.log .";
    system "rm -rf $base";
    system "rm -rf $savedir";
    unlink $conf_file;

};

#超A&G
subtest 'A&G' => sub {
    my $conf_file = 'radiko.ini.test';
    my $config = new Config::Tiny;
    $config->{global}{rtmpdump_path} = '/usr/local/bin/rtmpdump';
    $config->{global}{swfextract_path} = '/usr/local/bin/swfextract';
    $config->{global}{ffmpeg_path} = '/usr/local/bin/ffmpeg';
   $config->{global}{workdir} = './testbase';
    $config->{global}{savedir} = './savedir';
    $config->{global}{debug} = 1;
    $config->{a_and_g}{url} = 'rtmp://fms-base1.mitene.ad.jp/agqr/aandg22';
    $config->write($conf_file);

    my $recorder = new Record({
        conf => $conf_file,
    });

    my $base = $config->{global}{workdir};
    my $file = "test.flv";
    $recorder->start(
        $file,
        'A&G',
        1,
    );

    {
        my $size = -s "$base/$file";
        ok $size > 0, "rec ok $file";

        my $flv_file_type = `file $base/$file`;
        like $flv_file_type, qr/Macromedia Flash Video/, 'check flv file type';
    }

    my $savedir = $config->{global}{savedir};
    my $dest_file = 'test.mp3';

    $recorder->convert($file, $dest_file);

    ok -e "$savedir/$dest_file", 'convert ok';
    my $conv_file_type = `file $savedir/$dest_file`;

    like $conv_file_type, qr/MPEG ADTS/, 'check file type';


    system "cp testbase/proc.log .";
    system "rm -rf $base";
    system "rm -rf $savedir";
    unlink $conf_file;

};

#NHK
subtest 'radiru' => sub {
    my $conf_file = 'radiko.ini.test';
    my $config = new Config::Tiny;
    $config->{global}{rtmpdump_path} = '/usr/local/bin/rtmpdump';
    $config->{global}{swfextract_path} = '/usr/local/bin/swfextract';
    $config->{global}{ffmpeg_path} = '/usr/local/bin/ffmpeg';
   $config->{global}{workdir} = './testbase';
    $config->{global}{savedir} = './savedir';
    $config->{global}{debug} = 1;
    $config->{radiru}{player_url} = 'http://www3.nhk.or.jp/netradio/files/swf/rtmpe.swf';
    $config->{radiru}{url_R1} = 'rtmpe://netradio-r1-flash.nhk.jp';
    $config->{radiru}{url_R2} = 'rtmpe://netradio-r2-flash.nhk.jp';
    $config->{radiru}{url_FM} = 'rtmpe://netradio-fm-flash.nhk.jp';
    $config->{radiru}{playpath_R1} = 'NetRadio_R1_flash@63346';
    $config->{radiru}{playpath_R2} = 'NetRadio_R2_flash@63342';
    $config->{radiru}{playpath_FM} = 'NetRadio_FM_flash@63343';
    $config->write($conf_file);

    my $recorder = new Record({
        conf => $conf_file,
    });

    my $base = $config->{global}{workdir};
    my $file = "test.flv";
    ok $recorder->start(
        $file,
        'R1',
        1,
    ), 'start ok';

    {
        my $size = -s "$base/$file";
        ok $size > 0, "rec ok $file";

        my $flv_file_type = `file $base/$file`;
        like $flv_file_type, qr/Macromedia Flash Video/, 'check flv file type';
    }

    my $savedir = $config->{global}{savedir};
    my $dest_file = 'test.mp3';

    ok $recorder->start(
        $file,
        'R2',
        1,
    ), 'start ok';

    {
        my $size = -s "$base/$file";
        ok $size > 0, "rec ok $file";

        my $flv_file_type = `file $base/$file`;
        like $flv_file_type, qr/Macromedia Flash Video/, 'check flv file type';
    }

    ok $recorder->start(
        $file,
        'FM',
        1,
    ), 'start ok';

    {
        my $size = -s "$base/$file";
        ok $size > 0, "rec ok $file";

        my $flv_file_type = `file $base/$file`;
        like $flv_file_type, qr/Macromedia Flash Video/, 'check flv file type';
    }
    $recorder->convert($file, $dest_file);

    ok -e "$savedir/$dest_file", 'convert ok';
    my $conv_file_type = `file $savedir/$dest_file`;

    like $conv_file_type, qr/MPEG ADTS/, 'check file type';


    system "cp testbase/proc.log .";
    system "rm -rf $base";
    system "rm -rf $savedir";
    unlink $conf_file;

};

done_testing;

