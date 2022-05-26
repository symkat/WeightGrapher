package WeightGrapher::Web::Controller::Dashboard;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($c) { 
    
    $c->stash->{graph_data} = $c->db->graph(1)->get_line_graph;
    $c->stash->{graph_json} = $c->db->graph(1)->get_line_graph_chartjs;
}

1;
