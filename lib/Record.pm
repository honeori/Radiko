package Record;

use Config::Tiny;
use LWP::UserAgent;
use HTTP::Request;
use File::Path qw{mkpath};

use Data::Dumper;

our $RTMPDUMP_PATH = '/usr/local/bin/rtmpdump';
our $SWFEXTRACT_PATH = '/usr/local/bin/swfextract';
our $FFMPEG_PATH = '/usr/local/bin/ffmpeg';

my @REQUIRED_COMMAND = (
    $RTMPDUMP_PATH,
    $SWFEXTRACT_PATH,
    $FFMPEG_PATH,
);

sub new {
    my $class = shift;
    my $opts = shift;

    foreach my $command (@REQUIRED_COMMAND) {
        if( ! -x $command) {
            die qq{can't execute $command};
        }
    }

    my $conf_file = $opts->{conf} // 'radiko.ini';
    my $config = new Config::Tiny->read($conf_file);

    my $ua = new LWP::UserAgent;

    my $this = bless {
        conf    => $config,
        ua      => $ua,
        debug   => $config->{global}{debug},
    }, $class;


    if( ! -d $config->{global}{workdir}) {
        mkpath $config->{global}{workdir};
    }

    if( ! -d $config->{global}{savedir}) {
        mkpath $config->{global}{savedir};
    }

    my $player_path = $this->_file_to_worksdir_path($config->{radiko}{player});
    my $keyfile = $this->_file_to_worksdir_path('authkey.png');
    $this->{keyfile} = $keyfile;

    if(! -e $player_path) {
        my $response = $ua->get(
            $config->{radiko}{player_url},
            ':content_file' => $player_path,
        );
        if(!$response->is_success) {
            unlink $player_path;
            die "can't get player file";
        }
        
        system "$SWFEXTRACT_PATH -b 14 $player_path -o $keyfile";
        if(! -e $keyfile) {
            unlink $player_path;
            die "can't get player file";
        }
    }

    if($this->{debug}) {
        my $file = 'proc.log';
        my $file = $this->_file_to_worksdir_path($file);
        open my $debug_fh, '>', $file or die "can't open $file$!";
        $this->{debug_fh} = $debug_fh;
    }

    return $this;
}

sub start {
    my $this = shift;

    my ($file_name, $station, $duration, $area) = @_;
    my $file = $this->_file_to_worksdir_path($file_name);


    my $request = HTTP::Request->new(
        POST => $this->{conf}{radiko}{auth1_url},
        [
            "pragma" => " no-cache",
            "X-Radiko-App" => " pc_1",
            "X-Radiko-App-Version" => " 2.0.1",
            "X-Radiko-User" => " test-stream",
            "X-Radiko-Device" => " pc",
        ],
    );

    my $response = $this->{ua}->request($request);
    if(!$response->is_success) {
        my $dump = Dumper($response);
        die "can't auth for auth1. $dump";
    }

    my $authtoken   = $response->header('X-Radiko-AuthToken');
    my $offset      = $response->header('X-Radiko-KeyOffset');
    my $length      = $response->header('X-Radiko-KeyLength');

    if(!($authtoken && $offset && $length)) {
        my $dump = Dumper($response);
        die "can't auth for auth1. $dump";
    }

    my $keyfile = $this->{keyfile};

    my $partialkey = `dd if=$keyfile bs=1 skip=$offset count=$length 2> /dev/null | base64`;

    my $request2 = HTTP::Request->new(
        POST => $this->{conf}{radiko}{auth2_url},
        [
            "pragma" => " no-cache",
            "X-Radiko-App" => " pc_1",
            "X-Radiko-App-Version" => " 2.0.1",
            "X-Radiko-User" => " test-stream",
            "X-Radiko-Device" => " pc",
            "X-Radiko-AuthToken" => $authtoken,
            "X-Radiko-PartialKey" => $partialkey,
        ],
    );

    my $response2 = $this->{ua}->request($request2);
    if(!$response2->is_success) {
        my $dump = Dumper($response2);
        die "can't auth for auth2. $dump";
    }

    my ($areaid, $japanese_area_name, $area_name);
    #ex $response2->content
    #^M
    #^M
    #JP13,東京都,tokyo Japan^M
    foreach my $line (split /\r?\n/, $response2->content) {
        if($line =~ /,/) {
            ($areaid, $japanese_area_name, $area_name) = split /,/, $line;
            last;
        }
    }

    if(!$areaid) {
        my $dump = Dumper($response2);
        die "can't auth for auth2. $dump";
    }

    $area //= $areaid;

    #finish authentication.

    $this->_start_record($file, $station, $duration, $areaid, $authtoken);
}

sub convert {
    my $this = shift;

    my ($src, $dest) = @_;

    my $src = $this->_file_to_worksdir_path($src);
    my $dest = $this->_file_to_savedir_path($dest);

    if( ! -e $src) {
        die "there is no $src";
    }
    my $command = qq{$FFMPEG_PATH -y -i "$src" -acodec mp3 "$dest"};

    use Data::Dumper; $this->_debug_print(Dumper($command));

    system $command;
}

sub _file_to_worksdir_path {
    my $this = shift;
    my $file = shift;
    return "$this->{conf}{global}{workdir}/$file";
}

sub _file_to_savedir_path {
    my $this = shift;
    my $file = shift;
    return "$this->{conf}{global}{savedir}/$file";
}

sub _start_record {
    my $this = shift;

    my ($file, $station, $duration, $area, $authtoken) = @_;

    my $playerurl = $this->{conf}{radiko}{player_url};

    my $record_command = qq{
        $RTMPDUMP_PATH -v
        -r "rtmpe://f-radiko.smartstream.ne.jp"
        --playpath "simul-stream.stream"
        --app "$station/_definst_"
        -W $playerurl
        -C S:"" -C S:"" -C S:"" -C S:$authtoken
        --live
        --stop $duration
        -o "$file"
    };

    $record_command =~ s/\n//g;

    use Data::Dumper; $this->_debug_print(Dumper($record_command));

    my $result = system $record_command;
}

sub _debug_print {
    my $this = shift;
    my $msg = shift;
    if(!$this->{debug}) {
        return;
    }

    if($msg !~ /\n\z/) {
        $msg .= "\n";
    }

    my $fh = $this->{debug_fh};
    print $fh $msg;
}

1;
##!/bin/sh
#
#date=`date '+%Y-%m-%d-%H:%M'`
##date=`date '+%Y-%m-%d'`
#playerurl=http://radiko.jp/player/swf/player_3.0.0.01.swf
#home=/home/stlange/script/radiko
#playerfile=$home/player.swf
#keyfile=$home/authkey.png
#
#if [ $# -eq 3 ]; then
#  station=$1
#  DURATION=`expr $2 \* 60`
#  showName=$3
#else
#  echo "usage : $0 station_name duration(minuites) showName"
#  exit 1
#fi
#
##
## get player
##
#if [ ! -f $playerfile ]; then
#  wget -q -O $playerfile $playerurl
#
#  if [ $? -ne 0 ]; then
#    echo "failed get player"
#    exit 1
#  fi
#fi
#
##
## get keydata (need swftool)
##
#if [ ! -f $keyfile ]; then
#  /usr/local/bin/swfextract -b 14 $playerfile -o $keyfile
#
#  if [ ! -f $keyfile ]; then
#    echo "failed get keydata"
#    exit 1
#  fi
#fi
#
#if [ -f auth1_fms ]; then
#  rm -f auth1_fms
#fi
#if [ -f auth1_fms.1 ]; then
#  rm -f auth1_fms.*
#fi
#
##
## access auth1_fms
##
#wget -q \
#     --header="pragma: no-cache" \
#     --header="X-Radiko-App: pc_1" \
#     --header="X-Radiko-App-Version: 2.0.1" \
#     --header="X-Radiko-User: test-stream" \
#     --header="X-Radiko-Device: pc" \
#     --post-data='\r\n' \
#     --no-check-certificate \
#     --save-headers \
#https://radiko.jp/v2/api/auth1_fms
#
#if [ $? -ne 0 ]; then
#  echo "failed auth1 process"
#  exit 1
#fi
#
##
## get partial key
##
#authtoken=`perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)' auth1_fms`
#offset=`perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)' auth1_fms`
#length=`perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)' auth1_fms`
#
#partialkey=`dd if=$keyfile bs=1 skip=${offset} count=${length} 2> /dev/null | base64`
#echo "authtoken: ${authtoken} \noffset: ${offset} length: ${length} \npartialkey: 
#
#$partialkey"
#
#rm -f auth1_fms
#
#if [ -f auth2_fms ]; then
#  rm -f auth2_fms
#fi
#
#if [ -f auth2_fms.1 ]; then
#  rm -f auth2_fms.*
#fi
##
## access auth2_fms
##
#wget -q \
#     --header="pragma: no-cache" \
#     --header="X-Radiko-App: pc_1" \
#     --header="X-Radiko-App-Version: 2.0.1" \
#     --header="X-Radiko-User: test-stream" \
#     --header="X-Radiko-Device: pc" \
#     --header="X-Radiko-Authtoken: ${authtoken}" \
#     --header="X-Radiko-Partialkey: ${partialkey}" \
#     --post-data='\r\n' \
#     --no-check-certificate \
#https://radiko.jp/v2/api/auth2_fms
#
#if [ $? -ne 0 -o ! -f auth2_fms ]; then
#  echo "failed auth2 process"
#  exit 1
#fi
#
#echo "authentication success"
#areaid=`perl -ne 'print $1 if(/^([^,]+),/i)' auth2_fms`
#echo "areaid: $areaid"
#
#rm -f auth2_fms
#
##
## rtmpdump
##
##/opt/rtmpdump-2.4/rtmpdump -v \
#/usr/local/bin/rtmpdump -v \
#         -r "rtmpe://f-radiko.smartstream.ne.jp" \
#         --playpath "simul-stream.stream" \
#         --app "${station}/_definst_" \
#         -W $playerurl \
#         -C S:"" -C S:"" -C S:"" -C S:$authtoken \
#         --live \
#         --stop $DURATION \
#         -o "$home/${1}_${date}"
#
##ffmpeg -y -i "/tmp/${1}_${date}" -acodec libmp3lame "/var/www/test/audio/${1}_${date}.mp3"
##ffmpeg -y -i "./${1}_${date}" -acodec mp3 "./${1}_${date}.mp3"
##ffmpegだと動かない
#/usr/local/bin/ffmpeg -y -i "$home/${1}_${date}" -acodec mp3 "$home/${1}_${date}.mp3"
#
#if [ ! -d $home/${showName} ]; then
#  mkdir $home/${showName}
#  echo $home/${showName} >> $home/.gitignore
#  
#fi
#
#mv $home/${1}_${date}.mp3 $home/${showName}/${showName}_${date}.mp3
#
#
#rm "$home/${1}_${date}"
