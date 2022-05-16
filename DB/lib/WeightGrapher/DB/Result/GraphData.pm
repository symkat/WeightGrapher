use utf8;
package WeightGrapher::DB::Result::GraphData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

WeightGrapher::DB::Result::GraphData

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

=head1 TABLE: C<graph_data>

=cut

__PACKAGE__->table("graph_data");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'graph_data_id_seq'

=head2 graph_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'numeric'
  is_nullable: 0

=head2 ts

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "graph_data_id_seq",
  },
  "graph_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "numeric", is_nullable => 0 },
  "ts",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 graph

Type: belongs_to

Related object: L<WeightGrapher::DB::Result::Graph>

=cut

__PACKAGE__->belongs_to(
  "graph",
  "WeightGrapher::DB::Result::Graph",
  { id => "graph_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-05-16 02:06:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FRYI3nLTG41GkR8TPfrVsg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
