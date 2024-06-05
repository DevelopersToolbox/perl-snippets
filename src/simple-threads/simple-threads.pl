#!/usr/bin/env perl

use Parallel::ForkManager;

my $max_threads   = 5;
my $total_threads = 25;

my $pm = Parallel::ForkManager->new($max_threads); # number of parallel processes

sub actually_do_something
{
	my ($c) = @_;

	print "Thread number: $c\n";
	sleep 5;
}

for my $i (0 .. $total_threads)
{
	# Forks and returns the pid for the child:
	my $pid = $pm->start and next;

	#... do some work with $data in the child process ...
	actually_do_something($i);

	$pm->finish; # Terminates the child process
}

$pm->wait_all_children;

