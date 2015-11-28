package Radiko::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $this = shift;

    my $user = $this->param('user') || '';
    my $pass = $this->param('pass') || '';
        

    if(!$this->users->check($user, $pass)) {
        return $this->render;
    }
    $this->session(user => $user);

    $this->flash(message => 'Thanks for logging in.');
    $this->redirect_to('protected');
}

sub logged_in {
    my $this =shift;
    return 1 if $this->session('user');
    $this->redirect_to('index');
    return undef;
}

sub logout {
    my $this = shift;

    $this->session(expires => 1);
    $this->redirect_to('index');
}

1;
