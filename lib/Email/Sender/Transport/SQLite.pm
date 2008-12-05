package Email::Sender::Transport::SQLite;
use Squirrel;
extends 'Email::Sender::Transport';

use DBI;

has _dbh => (
  is       => 'rw',
  init_arg => undef,
);

has _dbh_pid => (
  is       => 'rw',
  init_arg => undef,
  default  => sub { $$ },
);

sub dbh {
  my ($self) = @_;

  ## no critic Punctuation
  my $existing_dbh = $self->_dbh;

  return $existing_dbh if $existing_dbh and $self->_dbh_pid == $$;

  my $must_setup = ! -e $self->db_file;
  my $dbh        = DBI->connect("dbi:SQLite:dbname=" . $self->db_file);

  $self->_dbh($dbh);
  $self->_dbh_pid($$);
  $self->_setup_dbh if $must_setup;

  return $dbh;
}

has db_file => (
  is      => 'ro',
  default => 'email.db',
);

sub _setup_dbh {
  my ($self) = @_;
  my $dbh = $self->_dbh;
  $dbh->do('
    CREATE TABLE emails (
      id INTEGER PRIMARY KEY,
      body varchar NOT NULL,
      env_from varchar NOT NULL
    );
  ');
  $dbh->do('
    CREATE TABLE recipients (
      id INTEGER PRIMARY KEY,
      email_id integer NOT NULL,
      env_to varchar NOT NULL
    );
  ');
}

sub send_email {
  my ($self, $email, $env) = @_;

  my $message = $email->as_string;
  my $to      = $env->{to};
  my $from    = $env->{from};

  my $dbh = $self->dbh;

  $dbh->do("INSERT INTO emails (body, env_from) VALUES (?, ?)",
    undef, $message, $from,);

  my $id = $dbh->last_insert_id((undef) x 4);

  for my $addr (@$to) {
    $dbh->do("INSERT INTO recipients (email_id, env_to) VALUES (?, ?)",
      undef, $id, $addr,);
  }

  return $self->success;
}

no Squirrel;
1;
