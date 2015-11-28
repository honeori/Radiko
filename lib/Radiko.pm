package Radiko;
use Mojo::Base 'Mojolicious';

use Radiko::Model::Users;

sub startup {
    my $this = shift;

    $this->secrets(['Mojolicious rocks']);

    $this->helper( 
        users => sub { 
            state $users = Radiko::Model::Users->new 
        }
    );
    
    my $r = $this->routes;

    $r->any('/')->to('login#index')->name('index');

    my $logged_in = $r->under('/')->to('login#logged_in');
    $logged_in->get('/protected')->to('login#protected');

    $r->get('logout')->to('login#logout');
}

1;
