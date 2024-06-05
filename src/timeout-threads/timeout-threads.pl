#!/usr/bin/env perl

use strict;
use warnings;

use Parallel::ForkManager;

use constant PATIENCE => 3;

our %workers;
our %threads;

my $max_threads   = 15;
my $total_threads = 100;

sub actually_do_something
{
	my ($c) = @_;

	print "Thread number: $c\n";
	sleep 5;
}

sub dismiss_hung_workers
{
	while (my ($pid, $started_at) = each %workers)
	{
		next unless time() - $started_at > PATIENCE;
		print "Timeout for thread $threads{$pid} (PID $pid)\n";
		kill TERM => $pid;
		delete $threads{$pid};
		delete $workers{$pid};
	}
}

sub main
{
	my $pm = Parallel::ForkManager->new($max_threads); # number of parallel processes

	$pm->run_on_wait(\&dismiss_hung_workers, 1); # 1 second between callback invocations

	for my $i (0 .. $total_threads)
	{
		if (my $pid = $pm->start)
		{
			$threads{$pid} = $i;
			$workers{$pid} = time();
			next;
		}

		#... do some work with $data in the child process ...
		actually_do_something($i);

		$pm->finish; # Terminates the child process
	}
	$pm->wait_all_children;
}

&main;

