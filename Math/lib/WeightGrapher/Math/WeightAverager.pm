package WeightGrapher::Math::WeightAverager;
use warnings;
use strict;
use Data::Dumper;
$Data::Dumper::Indent = 1;
use Carp;

our $day_length = 60*60*24;

sub new {
    my $class = shift;
    my $self = {@_};
    # decay 10% per day by default.
    $self->{days_for_averaging} ||= 10;
    # The trend shows where we think we were some days ago.
    $self->{trend_back} ||= $self->{days_for_averaging};
    $self->{correction_window} ||= $self->{days_for_averaging};
    $self->{data} ||= [];
    $self->{preprocessed} = 0;
    $self->{count} = scalar @{ $self->{data} };
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

# Predict a single point of time from a single data point.
sub predict_from_dp {
    my ($self, $dp, $ts) = @_;
    return $dp->{average_value}
        + ($ts - $dp->{average_ts}) * $dp->{rate_change_sec};
}

# Predict a single point of time from 2 data points.
# 
# For the trend we may predict a past time with a weighting as of
# a current time.  So $as_of_ts tells us the weighting to use while
# $predict_ts gives us the timestamp we are predicting.
sub predict_from_2_dp {
    my ($self, $prev_dp, $next_dp, $as_of_ts, $predict_ts) = @_;
    $predict_ts ||= $as_of_ts;

    my $prev_prediction = $self->predict_from_dp($prev_dp, $predict_ts);
    my $next_prediction = $self->predict_from_dp($next_dp, $predict_ts);

    # If we are x of the way through the interval, the previous point will
    # be weighted at (1-x)^2 while the next will be weighted x^2.  This
    # gives a 3rd degree polynomial passing through where each point thinks
    # it should be, with the right rate at that point.
    my $prev_weight = ($next_dp->{ts} - $as_of_ts)**2;
    my $next_weight = ($as_of_ts - $prev_dp->{ts})**2;

    return ($prev_prediction * $prev_weight
            + $next_prediction * $next_weight
        ) / ($prev_weight + $next_weight);
}

# Predict from the last dp;
sub predict_from_last_dp {
    my ($self, $ts) = @_;
    if (0 == $self->{count}) {
        return 0;
    }
    else {
        my $dp = $self->{data}[-1];
        return $dp->{average_value}
            + ($ts - $dp->{average_ts}) * $dp->{rate_change_sec};
    }
}

sub process_dp_by_id {
    my ($self, $i) = @_;
    my $dp = $self->{data}[$i];

    my $prev_dp = {
        ts => 0,
        weight => 0,
        average_value=> 0,
        average_weight=> 0,
        average_ts => 0,
        rate_weight => 0,
        rate_ts => 0,
        rate_change_sec => 0,
    };

    # Just kidding
    if (0 < $i) {
        $prev_dp = $self->{data}[$i-1];
    }

    $dp->{weight} //= 1;

    my $delay = ($dp->{ts} - $prev_dp->{ts}) / $day_length;
    # We start off just averaging, not doing a decaying average.
    my $decay_factor = 1;
    if ($self->{days_for_averaging} <= $i + 1) {
        # We are in exponentially weighted decay.
        $decay_factor = (1 - 1/$self->{days_for_averaging})**$delay;
    }
    my $weight = $prev_dp->{average_weight} * $decay_factor;
    $dp->{weight} //= 1;

    $dp->{average_weight} = $weight + $dp->{weight};
    $dp->{average_value} = (
            $prev_dp->{average_value} * $weight + $dp->{value} * $dp->{weight}
        ) / $dp->{average_weight};
    $dp->{average_ts} = (
            $prev_dp->{average_ts} * $weight + $dp->{ts} * $dp->{weight}
        ) / $dp->{average_weight};


    # We today's rate data is taken as measured by now, with the change being from the
    # previous average to now.  We weigh it as the time from the previous average_ts
    # to now.
    my $rate_weight = $prev_dp->{rate_weight} * $decay_factor;
    my $this_rate_weight = (
            $dp->{ts} - $prev_dp->{average_ts}
        ) * $dp->{weight} / $day_length;
    $dp->{rate_weight} = $rate_weight + $this_rate_weight;
    $dp->{rate_ts} = (
            $prev_dp->{rate_ts} * $rate_weight
            + $dp->{ts} * $this_rate_weight
        ) / $dp->{rate_weight};
    my $this_change_per_second = (
            $dp->{value} - $prev_dp->{average_value}
        ) / ($dp->{ts} - $prev_dp->{average_ts});
    $dp->{rate_change_sec} = (
            $prev_dp->{rate_change_sec} * $rate_weight
            + $this_change_per_second * $this_rate_weight
        ) / $dp->{rate_weight};

    if ($i < 1) {
        # All rate stuff is measured from fake data - drop.
        $dp->{rate_weight} = 0;
        $dp->{rate_ts} = 0;
        $dp->{rate_change_sec} = 0;
    }
}

sub process_last_dp {
    my $self = shift;
    $self->process_dp_by_id($#{ $self->{data} });
}

sub preprocess {
    my $self = shift;
    return if $self->{preprocessed};

    for my $i (0..$#{ $self->{data} }) {
        $self->process_dp_by_id($i);
    }
    $self->{preprocessed} = 1;
}

# The trend tries to predict where you likely were trend_back days.
# EXCEPT at startup, we can't, so we actually delay it by a reasonable
# curve that starts at the first timestamp, then winds up at the right
# delay by 2 * trend_back days.
#
# That curve is described by x + x^2 - x^3 where x is the fraction of
# the way you are between the start and end of that startup period.
sub trend_timeseries {
    my ($self, @ts_array) = @_;

    $self->preprocess();

    if (0 == $self->{count}) {
        # Best we can do.
        return map 0, @ts_array; # Happens with empty buckets.
    }

    my @answer;
    my $start_ts = $self->{data}[0]{ts};
    my $delay_period = $self->{trend_back} * 24 * 60 * 60;
    my $end_startup_ts = $start_ts + 2 * $delay_period;
    my $i_data = 0;
    for my $ts (@ts_array) {
        # Find the right place in the array.
        while ($i_data < $self->{count} and $self->{data}[$i_data]{ts} < $ts) {
            $i_data++;
        }

        my $predict_ts = $start_ts;

        my $delay_trend = $delay_period;
        if ($ts < $start_ts) {
            $delay_trend = 0;
        }
        elsif ($ts < $end_startup_ts) {
            my $x = ($ts - $start_ts) / (2 * $delay_period);
            $delay_trend = $delay_period * ($x + $x**2 - $x**3);
        }

        if ($i_data == 0) {
            # Predict from starting point.
            push @answer, $self->predict_from_dp(
                $self->{data}[$i_data], $ts, $ts - $delay_trend);
        }
        elsif ($self->{count} <= $i_data) {
            # Predict from end point.
            push @answer, $self->predict_from_dp(
                $self->{data}[$self->{count} - 1], $ts, $ts - $delay_trend);
        }
        else {
            # Predict from both.
            push @answer, $self->predict_from_2_dp(
                $self->{data}[$i_data - 1], $self->{data}[$i_data], $ts, $ts - $delay_trend
            );
        }
    }

    return @answer;
}

# In the event that this is a discrepancy series, this issues a correction.
# The correction is - average_value, adjusted to be as small as possible based
# on rate_change_sec.  And, in the first few times, we adjust it closer to 0
# to encourage prediction logic to be in the predictor, not the correction.
sub find_correction {
    my $self = shift;
    if (0 == $self->{count}) {
        return 0; # Can't correct
    }
    my $dp = $self->{data}[-1];
    my $correction = - $dp->{average_value};
    my $correction_window = $self->{correction_window} * $day_length;
    my $max_delta = $correction_window * abs($dp->{rate_change_sec});
    if (abs($correction) <= $max_delta) {
        return 0;
    }
    elsif (0 < $correction) {
        $correction -= $max_delta;
    }
    else {
        $correction += $max_delta;
    }

    if ($self->{count} < 5) {
        $correction *= $self->{count} / 5;
    }
    return $correction;
}

sub predicted_at_future_target {
    my ($self, $target_value) = @_;
    if (0 == $self->{count}) {
        return undef;
    }
    my $dp = $self->{data}[-1];
    if (abs($dp->{rate_change_sec}) < 0.01 / $day_length) {
        return undef;
    }

    # We are trying to predict when the TREND hits target.
    #                  Starting time
    my $predicted_ts = $dp->{average_ts}
        # How much time to reach target.
        + ($target_value - $dp->{average_weight}) / $dp->{rate_change_sec}
        # How long it takes the trend to get there.
        + $self->{trend_behind} * $day_length;
    if ($predicted_ts < $dp->{ts}) {
        return undef;
    }
    else {
        return $predicted_ts;
    }
}

1;
