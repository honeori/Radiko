package RadikoDb;
use strict;
use warnings;
use DBI;
use DateTime;

my $RADIKO_DB = 'radiko.db';

my @CREATE_TABLES = (
q{CREATE TABLE IF NOT EXISTS show_list (
  showid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  title TEXT NOT NULL,
  date  TEXT NOT NULL,
  station TEXT NOT NULL,
  keyword TEXT NOT NULL,
  path TEXT NOT NULL)},
q{CREATE TABLE IF NOT EXISTS lineup (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  xml  TEXT NOT NULL,
  date  TEXT NOT NULL)},
q{CREATE UNIQUE INDEX IF NOT EXISTS date ON lineup (date)},
q{CREATE UNIQUE INDEX IF NOT EXISTS date ON show_list (date)}
);

my $INSERT_SHOW_QUERY = q {
  INSERT INTO show_list (title, date, station, keyword, path) values(?,?,?,?,?)
};
my %SELECT_SHOW_QUERY = (
  all  => 'SELECT * FROM show_list',
  date => 'SELECT title, date, station, keyword, path FROM show_list WHERE (date >= ? AND date < ?)',
  id   => 'SELECT title, date, station, keyword, path FROM show_list WHERE id = ?',
);
my $INSERT_LINEUP_QUERY = q {
  INSERT INTO lineup (xml,date) values(?,?)
};
my $HAS_RECORDED_IN_LINEUP_QUERY = q{
  SELECT id FROM lineup WHERE date = ?
};


sub new {
  my $class = shift;
  my $params = shift;
  my $dbName = defined($params->{dbName}) ? $params->{dbName} : $RADIKO_DB;
  $dbName =':memory:' if(defined($params->{debug}));
  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbName");
  foreach my $query (@CREATE_TABLES) {
    $dbh->do($query);
  }
  my $this = {
    DB => $dbh,
    dbName => $dbName,
  };

  return bless $this, $class;
}

sub getDB {
	my $this = shift;
	return $this->{DB};
}

sub showAllTables {
  my $this = shift;
  my $QUERY = q{select distinct(name) from sqlite_master where type ='table' order by name};
  my $sth = $this->_getSelectHandler($QUERY);
  while(my $row = $sth->fetchrow_array) {
    print $row;
    print "\n";
  }
}



sub _getSelectHandler {
  my $this = shift;
  my $query = shift;
  my $params = shift || [];
  
  my $dbh = $this->{DB};
  my $sth;
  eval {
    $sth = $dbh->prepare($query);
    $sth->execute(@$params);
  };
  if($@) {
    $dbh->rollback;
    $dbh->disconnect;
    die("selectError: $@");
  }
  return $sth;
}

sub selectShowAll {
  my $this = shift;
  return $this->_getSelectHandler($SELECT_SHOW_QUERY{all});
}

sub insertShows {
  my $this = shift;
  my $shows = shift;

  my $dbh = $this->{DB};
  eval {
    my $sth = $dbh->prepare($INSERT_SHOW_QUERY);
#INSERT INTO show_list (title, date, station, keyword, path) values(?,?,?,?,?)
    foreach my $show (@$shows) {
      foreach my $key (qw{title date station keyword path}) {
        if(!exists($show->{$key})) {
          print STDERR 'insertShows need', " $key\n";
          return undef;
        }
      }
      $sth->execute(
        $show->{title},
        $show->{date},
        $show->{station},
        $show->{keyword},
        $show->{path}
      );
    }
  };
  if($@) {
    $dbh->rollback;
    $dbh->disconnect;
    print STDERR 'failed to insert', "$@";
    return undef;
    #die("insertError: $@");
  }
  return 1;
}

sub insertLineup {
  my $this = shift;
  my ($xml, $date) = @_;
  my $DB = $this->{DB};
  if(!defined($date)) {
	  $date = DateTime->now( time_zone =>'local')->strftime('%Y%m%d %H:%M:%S');
  }
  eval {
    my $sth = $DB->prepare($INSERT_LINEUP_QUERY);
    $sth->execute($xml, $date);
	$DB->do($INSERT_LINEUP_QUERY, undef, $xml, $date);
  };
  if($@) {
    $DB->rollback;
    $DB->disconnect;
    die("insertLineupError: $@");
  }
  return 1;
}

sub hasRecordedInLineup {
  my $this = shift;
  my $date = shift;
  my $dbh = $this->{DB};
  my $rtnVal =  eval {
    my $sth = $dbh->prepare($HAS_RECORDED_IN_LINEUP_QUERY);
    $sth->execute($date);
    if($sth->fetchrow_array) {
      return 1;
    } else {
      return undef;
    }
  };
  if($@) {
    $dbh->rollback;
    $dbh->disconnect;
    die("selectError: $@");
  }
  return $rtnVal;
}


1;
