package WeightGrapher::Web::Controller::Graph;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Try::Tiny;
use DateTime;

sub do_create ($c) {
    $c->stash->{template} = 'graph/create';

    my $unit = $c->stash->{form_unit} = $c->param('unit');
    my $name = $c->stash->{form_name} = $c->param('name');
    
    push @{$c->stash->{errors}}, "Name is required" unless $name;
    push @{$c->stash->{errors}}, "Unit is required" unless $unit;

    return if $c->stash->{errors};

    my $graph = $c->stash->{person}->create_related('graphs', {
        name => $name,
        unit => $unit,
    });

    $c->redirect_to( $c->url_for( 'show_dashboard' ) );
}

sub share ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_data = $c->stash->{graph_data} = $graph->get_graph_data;
}

# Share gid with email address given if the email address given is a valid
# account.
sub do_share ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $email      = $c->stash->{form_email} = $c->param('email');
}

sub data ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_data = $c->stash->{graph_data} = $graph->get_graph_data;
}

sub settings ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_data = $c->stash->{graph_data} = $graph->get_graph_data;
}

sub import ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_data = $c->stash->{graph_data} = $graph->get_graph_data;
}

sub export ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_data = $c->stash->{graph_data} = $graph->get_graph_data;
}

sub do_data ($c) {

    my $value    = $c->param('value');
    my $when     = $c->param('when');
    my $graph_id = $c->param('graph_id');

    my $graph = $c->db->graph($graph_id);

    return unless $graph->person_id == $c->stash->{person}->id;


    $graph->create_related('graph_datas', {
        value => $value,
        ts    => $when, 
    });

}


1;
