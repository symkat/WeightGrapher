package WeightGrapher::Web::Controller::Dashboard::Graph;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Try::Tiny;
use DateTime;


sub editor ($c) {
    my $graph_id   = $c->stash->{graph_id}   = $c->param('graph_id');
    my $graph      = $c->stash->{graph}      = $c->db->graph($graph_id);
    my $graph_data = $c->stash->{graph_data} = $graph->get_graph_data;
}


1;
