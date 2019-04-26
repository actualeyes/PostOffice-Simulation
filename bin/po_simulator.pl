#!/usr/bin/perl -w
# po_simulator.pl --- command line driver for PostOffice::Simulator
# Author:  <actualeyes@gmail.com>
# Created: 24 Apr 2015
# Version: 0.01
# PODNAME: po_simulator.pl

use warnings;
use strict;
use Getopt::Long;
use PostOffice::Simulation;
use Pod::Usage;

# Defaults to 1 day

my $minutes = (60 * 24 );

my $help = 0;


GetOptions (
    "minutes=i" => \$minutes,
    "help|?"   => \$help,
) or die("Error in command line arguments\n");

pod2usage(1) if $help;


my $post_office_obj = PostOffice::Simulation->new;

$post_office_obj->run_simulation($minutes);

__END__

=head1 NAME

po_simulator.pl - command line driver for PostOffice::Simulator

=head1 SYNOPSIS

po_simulator.pl [options] args

      -opt --long      Option description
      -m   --minutes   Sets the number of minutes to test
      -h   --help      This menu

=head1 AUTHOR

Anthony Pallatto, E<lt>actualeyes@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by 

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
