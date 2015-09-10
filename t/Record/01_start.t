#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Record;

use Config::Tiny;

{
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

}




done_testing;

