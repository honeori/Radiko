package ReserveList;

use strict;
use warnings;

use Config::Tiny;
use LWP::UserAgent;
use XML::Simple qw(:strict);
use MongoDB;
use MongoDB::OID;

sub new {
	my $class = shift;
	my $config_file = shift;
	if( !(defined($config_file) && ( -e $config_file)) ) {
		return undef;
	}

	my $config = Config::Tiny->read($config_file);

	bless +{
		config => $config,
		ua	   => LWP::UserAgent->new,
	}, $class;
}

sub getSavingDateList {
	my $this = shift;
	return {};
}
sub getShowList {
	my $this = shift;

	my $content = $this->getRawShowList;
	return $this->_convertXml($content);
}

sub _convertXml {
	my $this = shift;
	my $content = shift;

	my $xmlin = XMLin($content, 
		ForceArray => ['prog','station','meta'], 
		KeyAttr => {},
		SuppressEmpty => '',
	);

	my @rtn_array = ();
	foreach my $station ( @{$xmlin->{stations}{station}} ) {
		my $id = $station->{id};
		my $name = $station->{name};
		my $date = $station->{scd}{progs}{date};
		foreach my $prog (@{$station->{scd}{progs}{prog}}) {
			$prog->{station_id} = $id;
			$prog->{station_name} = $name;
			$prog->{date} = $date;
			$prog->{metas} = $prog->{metas}{meta};
			push @rtn_array, $prog;
		}
	}
	return @rtn_array;
}

sub getRawShowList {
	my $this = shift;

	my $retry_count = $this->{config}{RadikoAPI}{retry_count} // 3;
	my $content;
	foreach my $i (1..$retry_count) {
		my $response =  $this->{ua}->get($this->_constructAPIURL);
		if(defined($response) && $response->is_success) {
			$content = $response->content;
			last;
		} else {
			sleep 1;
		}
	}

	return unless(defined($content));

	return $content;
}

sub _constructAPIURL {
	my $this = shift;
	my $radikoAPI = $this->{config}{RadikoAPI};
	my $uri = URI->new($radikoAPI->{url});
	$uri->query_form(area_id => $radikoAPI->{area_id});
	return $uri->as_string;
}

1;
