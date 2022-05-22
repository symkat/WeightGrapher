use utf8;
package WeightGrapher::DB::Result::Graph;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

WeightGrapher::DB::Result::Graph

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::InflateColumn::Serializer>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "InflateColumn::Serializer");

=head1 TABLE: C<graph>

=cut

__PACKAGE__->table("graph");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'graph_id_seq'

=head2 person_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 unit

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "graph_id_seq",
  },
  "person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "unit",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 graph_datas

Type: has_many

Related object: L<WeightGrapher::DB::Result::GraphData>

=cut

__PACKAGE__->has_many(
  "graph_datas",
  "WeightGrapher::DB::Result::GraphData",
  { "foreign.graph_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 graph_settings

Type: has_many

Related object: L<WeightGrapher::DB::Result::GraphSetting>

=cut

__PACKAGE__->has_many(
  "graph_settings",
  "WeightGrapher::DB::Result::GraphSetting",
  { "foreign.graph_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 person

Type: belongs_to

Related object: L<WeightGrapher::DB::Result::Person>

=cut

__PACKAGE__->belongs_to(
  "person",
  "WeightGrapher::DB::Result::Person",
  { id => "person_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-05-16 02:06:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l7TWCGRUfYez4zo/q59IRA

sub get_graph_data {
    my ( $self ) = @_;

    my $before = DateTime->now;
    my $after  = DateTime->now->subtract( days => 30 );

    my $dtf = $self->result_source->schema->storage->datetime_parser;

    # Time span -
    my $results = $self->search_related( 'graph_datas',
        {
            ts => {
                '>' => [ $dtf->format_datetime($after)  ],
                '<' => [ $dtf->format_datetime($before) ],
            },
        },
        {
            order_by => { -asc => 'ts' },
        }
    );
    
    my %data;
    while ( defined ( my $result = $results->next ) ) {
        $data{$result->ts->strftime("%Y-%m-%d")} = $result->value;
    }
    
    my $stream  = [];
    my $fullmap = [];
    foreach my $day ( 0 .. $before->delta_days($after)->in_units('days') ) {
        my $date = $after->strftime("%Y-%m-%d");
        push @{$fullmap}, { date => $date, value => exists $data{$date} ? $data{$date} : undef };
        push @{$stream}, exists $data{$date} 
            ? $data{$date} 
            : [];
        $after->add( days => 1 );
        print $after->strftime("%Y-%m-%d") . "\n";
    }

    return {
        data    => \%data,
        stream  => $stream,
        fullmap => $fullmap,
    };
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
