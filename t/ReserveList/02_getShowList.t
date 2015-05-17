#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Mock::LWP::Conditional;
use HTTP::Response;
use Config::Tiny;

use ReserveList;

subtest 'get todays list' => sub {
	my $config_file = '__test_config.ini';
	my $today_xml = q{<?xml version="1.0" encoding="UTF-8"?><radiko>
  <ttl>1800</ttl>
  <srvtime>1431796776</srvtime>
  <stations>
    <station id="MRO">
      <name>MRO北陸放送ラジオ</name>
      <scd>
        <progs>
          <date>20150516</date>
          <prog ft="20150516051000" to="20150516051500" ftl="0510" tol="0515" dur="300">
            <title>心の　いこい</title>
            <sub_title></sub_title>
            <pfm></pfm>
            <desc></desc>
            <info></info>
            <metas>
              <meta name="twitter-hash" value="#radiko" />
              <meta name="twitter" value="#radiko" />
              <meta name="facebook-fanpage" value="http://www.facebook.com/radiko.jp" />
            </metas>
            <url></url>
          </prog>
        </progs>
      </scd>
    </station>
    </stations>
</radiko>
	};
	open my $fh, '>', $config_file or die;
	print $fh q{
[RadikoAPI]
url = http://radiko.jp/v2/api/program/today
area_id = JP13
};
	close $fh;

	my $config= Config::Tiny->read($config_file);
	my $uri = URI->new($config->{RadikoAPI}{url});
	$uri->query_form(area_id => $config->{RadikoAPI}{area_id});

	my $stub_response = HTTP::Response->new(200);
	$stub_response->content($today_xml);
	Test::Mock::LWP::Conditional->stub_request(
		$uri->as_string => $stub_response,
	);
	my @list = ReserveList->new($config_file)->getShowList;
	use Data::Dumper; diag Dumper(\@list);
	use utf8;
	is_deeply \@list, [
		{
			ft			=> '20150516051000',
			to			=> '20150516051500',
			ftl			=> '0510',
			tol			=> '0515',
			dur			=> '300',
			title		=> '心の　いこい',
			sub_title	=> '',
			pfm			=> '',
			desc		=> '',
			info		=> '',
			metas		=> [
				{ name => 'twitter-hash', value=>'#radiko' },
				{ name => 'twitter', value=>'#radiko' },
				{ name => 'facebook-fanpage', value=>'http://www.facebook.com/radiko.jp' },
			],
			url			=> '',
			date		=> '20150516',
			station_id	=> 'MRO',
			station_name => 'MRO北陸放送ラジオ',
		},
	];
	no utf8;

	unlink $config_file;
};

done_testing;

