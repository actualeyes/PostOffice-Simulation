#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch
# 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01_postoffice.t'

# Test file created outside of h2xs framework.
# Run this like so: `perl 01_postoffice.t'
#    <actualeyes@gmail.com>     2015/04/21 12:28:53

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use Test::More qw( no_plan );
BEGIN { use_ok( 'PostOffice::Simulation' ); }
#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# 1) 60 persent chance a new customer enters
# 2) There are two clerks
# 3) If there is nobody in line and a server is free the customer does not wait to be served
# 4) When a customer is being served there is a 25% chance they will complete their business and leave
# 5) When a clerk is free he will take the next customer in line in the order that they arrived

my $post_office_obj = PostOffice::Simulation->new;


run_probability_tests("customer_completes_business", .25, "customers complete business at 25% probability");
run_probability_tests("new_customer_enters", .60, "new customer probability of 60%");
run_probability_tests("customer_gives_up", .05, "customer gives up probability of 5%");

# Clerk tests

my $clerks = $post_office_obj->clerks;

is($clerks->[0]->customer, 0, "Clerk 1 is available by default" );
is($clerks->[1]->customer, 0, "Clerk 2 is available by default" );

my $available_clerk = $post_office_obj->get_available_clerk;

is($available_clerk, 0, "The first clerk is the first to be assigned");

$clerks->[0]->customer(1);

my $available_clerk = $post_office_obj->get_available_clerk;

is($available_clerk, 1, "The Second clerk is assigned if first is occupied");

$clerks->[1]->customer(2);

my $available_clerk = $post_office_obj->get_available_clerk;

is($available_clerk, '', "Returns empty string if no clerks available");


is ($post_office_obj->line_length, 0, "default line is empty");

# Add people to line

$post_office_obj->customer_enters_line(5);
$post_office_obj->customer_enters_line(6);
$post_office_obj->customer_enters_line(7);
$post_office_obj->customer_enters_line(8);
$post_office_obj->customer_enters_line(9);
$post_office_obj->customer_enters_line(10);
$post_office_obj->customer_enters_line(11);
$post_office_obj->customer_enters_line(12);
$post_office_obj->customer_enters_line(13);
$post_office_obj->customer_enters_line(14);


is_deeply($post_office_obj->line,[5,6,7,8,9,10,11,12,13,14],"Original Customer list comprised as expected");

is ($post_office_obj->line_length, 10, "line increases by 10 after customer enters line");

my $next_customer_id = $post_office_obj->service_next_customer;
is ($next_customer_id, 5, "Served person in front of line");

is ($post_office_obj->line_length, 9, "line decreases by one after customer leaves line");

is($post_office_obj->unserved_customers, 0, "Unserved customers defaults to 0");

my $departing_customer_id = $post_office_obj->customer_leaves_line(9, 11, 13);


is($post_office_obj->unserved_customers, 3, "Unserved customers increased to 3 after departure");


is_deeply($post_office_obj->line,[6,7,8,10,12,14],"Removed 9, 11, and 1 from line");

is($post_office_obj->line_length, 6, "Expected line length after removals"); 





sub run_probability_tests {
    my ($method, $expected_probability) = @_;

    my $matches = 0;
    my $sample_size = 100000;
    
    foreach (0..$sample_size) {
        my $result = $post_office_obj->$method;
        if ($result == 1) {
            $matches += 1;
        }
    };
    
    my $actual_probability = ( $matches / $sample_size);
    my $upper_limit = $expected_probability + .005;
    my $lower_limit = $expected_probability - .005;
    
    cmp_ok( $actual_probability, '<=', $upper_limit, "$method simulation ratio is below $upper_limit");
    cmp_ok( $actual_probability, '>=', $lower_limit, "$method simulation ratio is above $lower_limit");
    
}
