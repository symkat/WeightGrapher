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

sub view ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_json = $c->stash->{graph_json} = $graph->get_line_graph_chartjs;
}

sub add ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_json = $c->stash->{graph_json} = $graph->get_line_graph_chartjs;
}

sub share ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_json = $c->stash->{graph_json} = $graph->get_line_graph_chartjs;
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
    my $graph_json = $c->stash->{graph_json} = $graph->get_line_graph_chartjs;
}

sub data_edit ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_json = $c->stash->{graph_json} = $graph->get_line_graph_chartjs;
}

# Handle data edit requests from /graph/N/data/edit panel
sub do_data_edit ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $data_id    = $c->stash->{data_id}    = $c->param('data_id');
    my $value      = $c->stash->{value}      = $c->param('value');

    my $record = $c->db->graph_data($data_id);

    # Only allow a user to update thier own graph data.
    if ( $record->graph->person->id != $c->stash->{person}->id ) {
        $c->redirect_to( $c->url_for( 'show_graph_data_edit', gid => $graph_id ) );
        return;
    }

    $record->value( $value );
    $record->update;

    $c->redirect_to( $c->url_for( 'show_graph_data_edit', gid => $graph_id ) );
}

# Handle data delete requests from /graph/N/data/edit panel
sub do_data_delete ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $data_id    = $c->stash->{data_id}    = $c->param('data_id');

    my $record = $c->db->graph_data($data_id);

    # Only allow a user to delete thier own graph data.
    if ( $record->graph->person->id != $c->stash->{person}->id ) {
        $c->redirect_to( $c->url_for( 'show_graph_data_edit', gid => $graph_id ) );
        return;
    }

    $record->delete;

    $c->redirect_to( $c->url_for( 'show_graph_data_edit', gid => $graph_id ) );
}

sub settings ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_json = $c->stash->{graph_json} = $graph->get_line_graph_chartjs;
}

sub import ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_json = $c->stash->{graph_json} = $graph->get_line_graph_chartjs;
}

sub export ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('gid');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_json = $c->stash->{graph_json} = $graph->get_line_graph_chartjs;
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

sub do_graph_share ($c) {

}

sub do_graph_add ($c) {

}

1;
