package WeightGrapher::Web;
use Mojo::Base 'Mojolicious', -signatures;
use WeightGrapher::DB;

sub startup ($self) {
    my $config = $self->plugin('NotYAMLConfig', { file => -e 'weightgrapher.yml' 
        ? 'weightgrapher.yml' 
        : '/etc/weightgrapher.yml'
    });

    # Configure the application
    $self->secrets($config->{secrets});

    # Set the cookie expires to 30 days.
    $self->sessions->default_expiration(2592000);

    # Load our custom commands.
    push @{$self->commands->namespaces}, 'WeightGrapher::Web::Command';

    $self->helper( db => sub {
        return state $db = WeightGrapher::DB->connect($config->{database}->{weightgrapher});
    });

    # Standard router.
    my $r = $self->routes->under( '/' => sub ($c)  {

        # If the user has a uid session cookie, then load their user account.
        if ( $c->session('uid') ) {
            my $person = $c->db->resultset('Person')->find( $c->session('uid') );
            if ( $person && $person->is_enabled ) {
                $c->stash->{person} = $person;
            }
        }

        return 1;
    });

    # Create a router chain that ensures the request is from an authenticated user.
    my $auth = $r->under( '/' => sub ($c) {

        # Logged in user exists.
        if ( $c->stash->{person} ) {
            return 1;
        }

        # No user account for this seession.
        $c->redirect_to( $c->url_for( 'show_login' ) );
        return undef;
    });

    # Create a router chain that ensures the request is from an admin user.
    my $admin = $auth->under( '/' => sub ($c) {

        # Logged in user exists.
        if ( $c->stash->{person}->is_admin ) {
            return 1;
        }

        # No user account for this seession.
        $c->redirect_to( $c->url_for( 'show_dashboard' ) );
        return undef;
    });

    # User registration, login, and logout.
    $r->get   ( '/register' )->to( 'Auth#register'    )->name('show_register' );
    $r->post  ( '/register' )->to( 'Auth#do_register' )->name('do_register'   );
    $r->get   ( '/login'    )->to( 'Auth#login'       )->name('show_login'    );
    $r->post  ( '/login'    )->to( 'Auth#do_login'    )->name('do_login'      );
    $auth->get( '/logout'   )->to( 'Auth#do_logout'   )->name('do_logout'     );

    # User Forgot Password Workflow.
    $r->get ( '/forgot'       )->to('Auth#forgot'    )->name('show_forgot' );
    $r->post( '/forgot'       )->to('Auth#do_forgot' )->name('do_forgot'   );
    $r->get ( '/reset/:token' )->to('Auth#reset'     )->name('show_reset'  );
    $r->post( '/reset/:token' )->to('Auth#do_reset'  )->name('do_reset'    );

    # User setting changes when logged in
    $auth->get ( '/profile'  )->to('UserSettings#profile'            )->name('show_profile'         );
    $auth->post( '/profile'  )->to('UserSettings#do_profile'         )->name('do_profile'           );
    $auth->get ( '/password' )->to('UserSettings#change_password'    )->name('show_change_password' );
    $auth->post( '/password' )->to('UserSettings#do_change_password' )->name('do_change_password'   );

    # Send requests for / to the dashboard.
    $r->get('/')->to(cb => sub ($c) {
        $c->redirect_to( $c->url_for('dashboard') );
    });

    # User dashboard
    $auth->get( '/dashboard'                 )->to('Dashboard#index'         )->name('show_dashboard'    );
    
    # User Create Graph
    $auth->get ( '/graph'                )->to('Graph#create'          )->name('show_graph_create'   );
    $auth->post( '/graph'                )->to('Graph#do_create'       )->name('do_graph_create'     );
    $auth->get ( '/graph/:gid'           )->to('Graph#view'            )->name('show_graph'    );
    $auth->get ( '/graph/:gid/add'       )->to('Graph#add'             )->name('show_graph_add'    );
    $auth->get ( '/graph/:gid/share'     )->to('Graph#share'           )->name('show_graph_share'    );
    $auth->post( '/graph/:gid/share'     )->to('Graph#do_share'        )->name('do_graph_share'      );
    $auth->get ( '/graph/:gid/data'      )->to('Graph#data'            )->name('show_graph_data'     );
    $auth->get ( '/graph/:gid/data/edit' )->to('Graph#data_edit'       )->name('show_graph_data_edit');
    $auth->get ( '/graph/:gid/settings'  )->to('Graph#settings'        )->name('show_graph_settings' );
    $auth->get ( '/graph/:gid/import'    )->to('Graph#import'          )->name('show_graph_import'   );
    $auth->get ( '/graph/:gid/export'    )->to('Graph#export'          )->name('show_graph_export'   );

    $auth->post( '/graph/:gid/data/edit'   )->to('Graph#do_data_edit'      )->name('do_graph_data_edit');
    $auth->post( '/graph/:gid/data/delete' )->to('Graph#do_data_delete'    )->name('do_graph_data_delete');
    $auth->post( '/graph/:gid/add'         )->to('Graph#do_add'            )->name('do_graph_add'    );
    $auth->post( '/graph/:gid/import'      )->to('Graph#do_import'         )->name('do_graph_import'   );
    $auth->post( '/graph/:gid/export'      )->to('Graph#do_export'         )->name('do_graph_export'   );


    $auth->post( '/graph/:graph_id/data' )->to('Graph#do_data'         )->name('do_graph_data'     );

}

1;
