package PostOffice::Simulation::Clerk;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

# ABSTRACT: Handles the status of a Post Office Clerk

has customer => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
);


__PACKAGE__->meta->make_immutable;

1;
