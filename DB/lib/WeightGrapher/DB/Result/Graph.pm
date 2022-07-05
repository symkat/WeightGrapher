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

use JSON::MaybeXS qw( encode_json );

sub get_line_graph_chartjs {
    my ( $self ) = @_;

    my $data = $self->get_graph_data;

    my $struct = {
        labels   => $data->{datemap},
        datasets => [
            {
                data        => [ map { $_->{value} ? +{ x => $_->{date}, y => $_->{value} } : (); } @{$data->{fullmap}} ],
                fill        => 0,
                borderColor => 'rgb(75, 192, 192)',
                tension     => 0.1,
                label       => 'weight',
            },
        ]
    };

    return $struct;
}

sub get_line_graph {
    my ( $self ) = @_;

    my $data = $self->get_graph_data;

    return {
        labels => $data->{datemap},
        data   => [ map {
            $_->{value} ? +{ x => $_->{date}, y => $_->{value} } : ();
        } @{$data->{fullmap}} ],
    };
}

sub get_graph_datastream {
    my ( $self ) = @_;
    
    return [  map  {
            +{ id => $_->id, date => $_->ts->strftime( "%F %T", value => $_->value ) }
        } $self->search_related( 'graph_datas', { }, {  order_by => { -asc => 'ts' } } )->all
    ];

}

use DateTime;
use WeightGrapher::Math::ComplexWeightAverager;
sub get_bens_graph {
    my ( $self ) = @_;

    # Construct @fake_dps from the real data...

    #    push @fake_dps, {
    #        day => $day,                              # The length of time, in seconds, we consider to be one day.
    #        ts => $start_ts + $day * $day_length,     # Unix time stamp
    #        value => fake_weight($ts),                # Value of the user's weight
    #    };
    #

    push my @fake_dps, map  { +{ 
        day   => 24*60*60,
        ts    => $_->ts->epoch,
        value => $_->value,
    } } $self->search_related( 'graph_datas', { }, {  order_by => { -asc => 'ts' } } )->all;

    my @graph_points;

    # NOTE: end_ts was replaced with the 7 days from now, start_ts was removed.

    my $averager = WeightGrapher::Math::ComplexWeightAverager->new(data => \@fake_dps);
    my @trend = $averager->trend_timeseries(map {$_->{ts}} @fake_dps);
    my $corrected_timeseries = $averager->{corrected_timeseries};
    my $corrected_data = $corrected_timeseries->{data};

    my @correction_by_dow = (0, 0, 0, 0, 0, 0, 0);

    my $count_trend_lower = 0;
    my $total_trend_higher = 0;
    for my $i (0..$#$corrected_data) {
        my $day = $fake_dps[$i]->{day};
        my $measured_weight = $fake_dps[$i]{value};
        my $corrected_weight = $corrected_data->[$i]{value};
        my $correction = $corrected_weight - $measured_weight;
        my $trend_weight = $trend[$i];
        my $predicted_final = $corrected_timeseries->predict_from_dp($corrected_data->[$i], DateTime->now->add( days => 7 )->epoch);
        my $day_of_week = $day % 7;
        $correction_by_dow[$day_of_week] = $correction;

        push @graph_points, {
            day              => $day,
            measured_weight  => $measured_weight,
            corrected_weight => $corrected_weight,
            trend            => $trend[$i],
            predicted_final  => $predicted_final,
            dow_correction_0 => $correction_by_dow[0],
            dow_correction_1 => $correction_by_dow[1],
            dow_correction_2 => $correction_by_dow[2],
            dow_correction_3 => $correction_by_dow[3],
            dow_correction_4 => $correction_by_dow[4],
            dow_correction_5 => $correction_by_dow[5],
            dow_correction_6 => $correction_by_dow[6],
        };

        #printf("%4i: meas %3.2f, adj %3.2f, trend %3.4f, final %3.2f [", $day, $measured_weight, $corrected_weight, $trend[$i], $predicted_final);
        #for my $i (0..6) {
        #    printf "% 1.2f,", $correction_by_dow[$i];
        #}
        #print "]\n";

        $total_trend_higher += $trend[$i] - $corrected_weight;
        if ($trend[$i] < $corrected_weight) {
            $count_trend_lower++;
        }
    }

    my $average_trend_higher = $total_trend_higher / @$corrected_data;

    return {
        average_trend_higher => $average_trend_higher,
        graph_points         => [ @graph_points ],
    };
}

sub get_graph_data {
    my ( $self ) = @_;

    my $before = DateTime->now;
    my $after  = DateTime->now->subtract( days => 60 );

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
    my $datemap = [];
    foreach my $day ( 0 .. $before->delta_days($after)->in_units('days') ) {
        my $date = $after->strftime("%Y-%m-%d");
        push @{$fullmap}, { date => $date, value => exists $data{$date} ? $data{$date} : undef };
        push @{$datemap}, $date;
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
        datemap => $datemap,
    };
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
