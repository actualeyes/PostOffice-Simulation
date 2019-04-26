package PostOffice::Simulation;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use PostOffice::Simulation::Clerk;

# ABSTRACT: Simulates PostOffice Customer Processes

has 'clerks' => (
    is  => 'rw',
    isa => 'ArrayRef[PostOffice::Simulation::Clerk]',
    default => sub {
        my $clerk_1 = PostOffice::Simulation::Clerk->new;
        my $clerk_2 = PostOffice::Simulation::Clerk->new;

        return [$clerk_1, $clerk_2 ];
    }
);

has 'line' => (
    is  => 'rw',
    isa => 'ArrayRef[Num]',
    default => sub {[]}
);

has 'customer_time_spent' => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub {{}},
);

has 'unserved_customers' => (
    traits => ['Number'],
    is  => 'rw',
    isa => 'Int',
    default => 0,
    handles   => {
        record_departure => 'add',
    },
);

has 'idle_clerk_time' => (
    traits => ['Number'],
    is  => 'rw',
    isa => 'Int',
    default => 0,
    handles   => {
        record_idle_clerk => 'add',
    },
);


=method customer_gives_up

returns 1 if a customer decides to leave whilst standing in line. The
chance that a customer decides to leave has a probability of 5% or 1/20.

=cut

sub customer_gives_up {
    my ($self) = @_;
    
    my $result = 1 + int(rand(20));
    
    return 1 if $result == 1; 
}

=method customer_completes_business

returns 1 if the customer completes their post office related errands
whilst at the clerk window. The chance that a customer completes
business has a probability of 25% 1/4.

=cut


sub customer_completes_business {
    my ($self) = @_;

    my $result = 1 + int(rand(4));
         
    return 1 if $result == 1; 
}

=method new_customer_enters

returns 1 if a customer enters the post office. The chance that a
customer arrives has a probability of 60% or 3/5.

=cut


sub new_customer_enters {
    
    my ($self) = @_;
    
    my $result = 1 + int(rand(5));
         
    return 1 if grep {/$result/} (1,2,3); 
    
}

=method  get_available_clerk

This method checks for available clerks. Returns either the array address of
an available clerk or empty string if there are no clerks available

=cut

sub get_available_clerk {
    
    my ($self) = @_;
    
    my $clerks = $self->clerks;
    for (0 .. $#$clerks) {
        if ( $clerks->[$_]->customer == 0 ) {
            return $_;
        }
    }
    
}

=method line_length

Returns the length of the line of customers

=cut

sub line_length {
    my ($self) = @_;

    my $line = $self->line;
    
    return scalar(@$line);
}

=method service_next_customer

Removes a customer from the line returns the customers unique id

=cut

sub service_next_customer {
    my ($self) = @_;

    my $line = $self->line;

    return shift @$line;
}

=method customer_enters_line

Adds a customer from the line

=cut


sub customer_enters_line {
    my ($self, $customer_id) = @_;
    
    my $line = $self->line;
    if ($customer_id =~ /^\d+$/ ) {
        push @$line, $customer_id;
    } else {
        die "Numeric Customer Id Required";
        
    }

}

=method check_for_impatient_customers

Check if the customer gives up and removes them from the line

=cut

sub check_for_impatient_customers {
    my ($self) = @_;
    my $line = $self->line;
    my @departing_customers;
    
    foreach my $customer (@$line) {
        if ($self->customer_gives_up) {
            push @departing_customers, $customer;
        }
    }

    if (scalar(@departing_customers) > 0 ) {
        $self->customer_leaves_line(@departing_customers);
    }


}

=method customer_leaves_line

remove a customer from the line and record their departure

=cut 

sub customer_leaves_line {
    my ($self, @departing_customers) = @_;
    my $line = $self->line;
    
    foreach my $customer_index (0..$#departing_customers ) {
        foreach my $line_index (0..$#$line) {
            if ($departing_customers[$customer_index] == @$line[$line_index]) {
                
                my $departure = splice(@$line, $line_index, 1 );

                $self->record_departure(1);
                last;
            }
        }
    }
    
    return @$line;
    
}


=method process_customer_business

Assigns customers to clerks and sends customers on their way 

=cut
    

sub process_customer_business {
    my ($self) = @_;
    my $clerks = $self->clerks;

    foreach (0 .. $#$clerks ) {
        if ($clerks->[$_]->customer > 0 && $self->customer_completes_business) {
            if ($self->line_length ==  0) {
                $clerks->[$_]->customer(0);
            } else {
                my $customer_id = $self->service_next_customer;
                $clerks->[$_]->customer($customer_id);
            }
        } elsif ($clerks->[$_]->customer == 0) {
            if ($self->line_length > 0) {
                my $customer_id = $self->service_next_customer;
                $clerks->[$_]->customer($customer_id);
            } else {
                $self->record_idle_clerk(1);
                
            }
        }
        
    }
}

=method welcome_new_customer

Decides if a customer can go right to a clerk or has to wait in line

=cut

sub welcome_new_customer {
    my ($self, $customer_id) = @_;
    my $clerks = $self->clerks;
    

    if ($self->new_customer_enters) {
        $self->customer_time_spent->{$customer_id} = 0;
        if ($self->line_length == 0) {
            my $clerk_id = $self->get_available_clerk;
            if ($clerk_id ne '') {
                $clerks->[$clerk_id]->customer($customer_id);
            } else {
                $self->customer_enters_line($customer_id);
            }
        } else {
            $self->customer_enters_line($customer_id);
        }
    }
}

=method update_customer_time_spent

increase the time spent count for all customers currently in the post
office

=cut 


sub update_customer_time_spent {
    my ($self) = @_;

    my $time_spent = $self->customer_time_spent;
    my $line = $self->line;

    foreach my $customer_id (@$line) {
        $time_spent->{$customer_id} += 1;
    }
}

=method get_avg_customer_time

Returns the average time a customer spent in the post office

=cut 

sub get_avg_customer_time {
    my ($self) = @_;

    my $customer_time_spent = $self->customer_time_spent;
    my $total_customers = scalar(keys %{$customer_time_spent});
    my $total_customer_time = 0;
    
    foreach my $customer ( keys %{$customer_time_spent}) {
        $total_customer_time += $customer_time_spent->{$customer};
    }

    my $avg_customer_time = ($total_customer_time / $total_customers);
    
    return $avg_customer_time 
}

=method get unserved_customer_rate

Returns the rate of unserved customers 

=cut

sub get_unserved_customer_rate {
    my ($self) = @_;

    my $customer_time_spent = $self->customer_time_spent;
    my $total_customers = scalar(keys %{$customer_time_spent});
    
    my $unserved_customer_rate = ($self->unserved_customers / $total_customers) * 100;
    
}


=method present_data

Gather all simulation and present it to the 


=cut


sub present_data {
    my ($self, $total_time) = @_;
    
    my $avg_customer_time        = sprintf("%.2f",$self->get_avg_customer_time);
    my $idle_clerk_rate          = sprintf("%.2f",($self->idle_clerk_time / $total_time) *100)."%";
    my $unserved_customer_rate   = $self->get_unserved_customer_rate;
    my $customer_time_spent      = $self->customer_time_spent;
    my $total_customers          = scalar(keys %{$customer_time_spent});
    
    print "Total customers Served:      $total_customers\n";
    print "Average time spent:          $avg_customer_time minutes\n";
    print "Idle clerk rate:             $idle_clerk_rate\n";
    print "Unserved customers:          ".$self->unserved_customers."\n";
    print "Unserved customer rate:      ".sprintf("%.2f",$unserved_customer_rate)."%\n";
}

=method run_simulation

Runs the post office simulation for a given number of minutes
takes an integer for minutes
=cut

sub run_simulation {
    my ($self, $minutes) = @_;

    foreach (0..$minutes) {
        $self->welcome_new_customer($_);
        $self->process_customer_business;
        $self->check_for_impatient_customers;
        $self->update_customer_time_spent;

    }
    $self->present_data($minutes);
}



__PACKAGE__->meta->make_immutable;

1;
