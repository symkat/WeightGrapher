package WeightGrapher::Math::ComplexWeightAverager;
use warnings;
use strict;
our $day_length = 24*60*60;
use lib ".";
use WeightGrapher::Math::WeightAverager;
use Data::Dumper;
$Data::Dumper::Indent = 1;

sub new {
    my $class = shift;
    my $self = {@_};
    # decay 10% per day by default.
    $self->{days_for_averaging} ||= 10;
    # The trend shows where we think we were some days ago.
    $self->{trend_back} ||= $self->{days_for_averaging};
    $self->{data} ||= [];
    $self->{preprocessed} = 0;
    $self->{count} = scalar @{ $self->{data} };

    # The timestamp for midnight.  Will default data.
    # If people move timezones, there will be complications.
    $self->{day_boundary} ||= 0;

    # Default to a 1 week cycle.
    $self->{cycles} ||= [7];

    # Default to no recorded periods.
    $self->{period_ts} ||= [];

    return bless $self;
}

# We expect an array of hashrefs with keys ts and value.
# Other keys will be inserted in preprocessing.
sub observe {
    my ($self, @data) = @_;
    $self->{preprocessed} = 0;

    @data = sort {$a->{ts} <=> $b->{ts}} @data;

    if (0 == $self->{count}) {
        $self->{data} = \@data;
    }
    elsif ($self->{data}[-1] < $data[0]) {
        push @{$self->{data}}, @data;
    }
    else {
        $self->{data} = [sort {$a->{ts} <=> $b->{ts}} @{ $self->{data} }, @data];
    }

    $self->{count} = scalar @{ $self->{data} };
}

# Set the cycles array.
sub record_cycles {
    my ($self, @cycles ) = @_;
    $self->{cycles} = \@cycles;
    $self->{preprocessed} = 0;
}

# Set the periods array.
sub record_period_ts {
    my ($self, @period_ts) = @_;
    $self->{period_ts} = \@period_ts;
    $self->{preprocessed} = 0;
}

# We start with a timeseries.
#
# For each day of the cycle, we will generate a timeseries of
# differences between predictions and measurements for that day.
# We use that to generate corrections for that day to the data to
# smooth out the trend.  We start trying to correct a little, then
# correct more as we are more sure of our corrections.
#
# BUT PROBLEM: If we subtract out corrections before predicting, how
# much logic is in the correcting, how much is in the predicting?
# We solve that by recording an average correction, and subtracting
# it from our data points.  This forces the prediction to learn the
# average correction.  Which in turn pushes the average correction
# to 0.
sub apply_cycle_correction {
    my ($self, $timeseries, $cycle) = @_;

    # These are for fixing per bucket discrepancies.
    my @correctors = map {
        new WeightGrapher::Math::WeightAverager(
            days_for_averaging => $self->{days_for_averaging} * $cycle,
            correction_window => $cycle * 5, # HACK ALERT
        )
    } 1..$cycle;

    # This is to force the overall prediction to learn the average correction.
    my $reverse_corrector = new WeightGrapher::Math::WeightAverager(
        days_for_averaging => $self->{days_for_averaging} * $cycle
    );

    # This is the adjusted timeseries.
    my $corrected_timeseries = new WeightGrapher::Math::WeightAverager(
        days_for_averaging => $self->{days_for_averaging},
        trend_back => $self->{trend_back},
    );

    my $prev_dp;
    for my $dp (@{ $timeseries->{data} }) {
        if (not $prev_dp) {
            # Only the first data point.  No correction logic.
            $corrected_timeseries->observe($dp);
            $corrected_timeseries->process_last_dp();
            $prev_dp = $dp;
            next;
        }

        # Calculate what we think should happen.
        my $day = int(($dp->{ts} - $dp->{day_boundary}) / $day_length);
        my $bucket = $day % $cycle;
        my $corrector = $correctors[$bucket];
        my $correction = $corrector->find_correction();
        my $average_correction = $reverse_corrector->predict_from_last_dp($dp->{ts});
        my $predicted_value = $corrected_timeseries->predict_from_last_dp($dp->{ts});

        # Now update everything.

        # The corrector is given the discrepancy between value and what we
        # would predict based on prediction and average corrector.
        $corrector->observe({
            ts => $dp->{ts},
            weight => $dp->{weight},
            value => $dp->{value} - $predicted_value + $average_correction,
        });
        $corrector->process_last_dp();

        # The reverse corrector is told the correction from the corrector.
        $reverse_corrector->observe({
            ts => $dp->{ts},
            weight => $dp->{weight},
            value => $correction,
        });
        $reverse_corrector->process_last_dp();

        # The timeseries is adjusted for the corrections.
        $corrected_timeseries->observe({
            ts => $dp->{ts},
            value => $dp->{value} + $correction - $average_correction,
            weight => $dp->{weight},
            day_boundary => $dp->{day_boundary},
        });
        $corrected_timeseries->process_last_dp();
    }

    return $corrected_timeseries;
}

# Processes all timeseries.
sub preprocess {
    my $self = shift;
    return if $self->{preprocessed};

    for my $dp (@{ $self->{data} }) {
        $dp->{day_boundary} ||= $self->{day_boundary};
    }

    my $timeseries = new WeightGrapher::Math::WeightAverager(
        days_for_averaging => $self->{days_for_averaging},
        trend_back => $self->{trend_back},
        data => $self->{data},
    );

    for my $cycle (@{ $self->{cycles} }) {
        $timeseries = $self->apply_cycle_correction($timeseries, $cycle);
    }

    $self->{corrected_timeseries} = $timeseries;
    $self->{preprocessed} = 1;
}

sub corrected_timeseries {
    my $self = shift;
    $self->preprocess;
    return @{ $self->{corrected_timeseries}{data} };
}

sub trend_timeseries {
    my ($self, @ts_array) = @_;
    $self->preprocess;
    return $self->{corrected_timeseries}->trend_timeseries(@ts_array);
}

sub predicted_at_future_target {
    my ($self, $target_value) = @_;
    $self->preprocess;
    return $self->{corrected_timeseries}->predicted_at_future_value($target_value);
}

1;
