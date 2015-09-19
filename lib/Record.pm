package Record;

use Config::Tiny;
use LWP::UserAgent;
use HTTP::Request;
use File::Path qw{mkpath};

use Data::Dumper;

our $RTMPDUMP_PATH = '/usr/local/bin/rtmpdump';
our $SWFEXTRACT_PATH = '/usr/local/bin/swfextract';
our $FFMPEG_PATH = '/usr/local/bin/ffmpeg';

my @REQUIRED_COMMAND = qw(
    rtmpdump_path
    swfextract_path
    ffmpeg_path
);

sub new {
    my $class = shift;
    my $opts = shift;


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

    foreach my $command (@REQUIRED_COMMAND) {
        if( ! -x $config->{global}{$command}) {
            #die qq{can't execute $command $config->{global}{$command}};
        }
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

    if($station eq 'A&G') {
        $this->_start_a_and_g($file_name, $duration);
    } elsif($station =~ /\A(?:R1|R2|FM)\z/) {
        $this->_start_radiru($file_name, $station, $duration);
    }else {
        $this->_start_radiko($file_name, $station, $duration, $area);
    }
}

sub _start_radiru {
    my $this = shift;
    my ($file_name, $station, $duration) = @_;

    my $file = $this->_file_to_worksdir_path($file_name);
    my $url = $this->{conf}{radiru}{"url_$station"};
    my $playpath = $this->{conf}{radiru}{"playpath_$station"};
    my $playerurl= $this->{conf}{radiru}{player_url};

    $this->_debug_print($file);

    my $record_command = qq{
        $RTMPDUMP_PATH
        -r "$url"
        --playpath "$playpath"
        --app "live"
        -W $playerurl
        --live 
        --stop $duration
        -o "$file"
    };

    $record_command =~ s/\n//g;

    use Data::Dumper; $this->_debug_print(Dumper($record_command));
    #use Data::Dumper; $this->_debug_print(Dumper($this->{conf}{playpath}));

    my $result = system $record_command;
    if($result == 0) {
        return 1;
    } else {
        return;
    }
}

sub _start_a_and_g {
    $this = shift;
    my ($file_name, $duration) = @_;

    my $file = $this->_file_to_worksdir_path($file_name);
    my $url = $this->{conf}{a_and_g}{url};

    my $record_command = qq{
        $RTMPDUMP_PATH -v
        -r "$url"
        --live
        --stop $duration
        -o "$file"
    };

    $record_command =~ s/\n//g;

    my $result = system $record_command;
}

sub _start_radiko {
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
    my $url = $this->{conf}{radiko}{url};

    my $record_command = qq{
        $RTMPDUMP_PATH -v
        -r "$url"
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
