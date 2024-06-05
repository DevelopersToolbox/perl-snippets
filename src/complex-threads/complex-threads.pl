#!/usr/bin/perl

use strict;
use warnings;

use Parallel::ForkManager;

use constant PATIENCE => 50;

my %workers     = ();
my %tids        = ();
my %pids        = ();

my $max_forks   = 3;
my $total_forks = 10;

sub actually_do_something
{
	my ($c) = @_;

	print "Fork ID number: $c\n";
	sleep 3;
}

sub my_defined
{
	my ($str) = @_;

	if ((!defined $str) || ($str eq ''))
	{
		return 0;
	}
	return 1;
}

sub cleanup_by_pid
{
	my ($pid) = @_;
	my $tid;

	if (exists($pids{$pid}))
	{
		$tid = $pids{$pid};
	}
	if (defined($tid) && exists($tids{$tid}))
	{
		delete $tids{$tid};
	}
	if (exists($pids{$pid}))
	{
		delete $pids{$pid};
	}
	if (exists($workers{$pid}))
	{
		delete $workers{$pid};
	}
	print "Timed out: $tid - $pid\n";
}

sub cleanup_by_threadid
{
	my ($tid) = @_;
	my $pid;

	if (exists($tids{$tid}))
	{
		$pid = $tids{$tid};
	}
	if (exists($tids{$tid}))
	{
		delete $tids{$tid};
	}
	if (defined($pid) && exists($pids{$pid}))
	{
		delete $pids{$pid};
	}
	if (defined($pid) && exists($workers{$pid}))
	{
		delete $workers{$pid};
	}

	print "Cleaned up: $tid - $pid\n";
}

sub dismiss_hung_workers
{
	while (my ($pid, $started_at) = each %workers)
	{
		next unless time() - $started_at > PATIENCE;
		kill TERM => $pid;
		cleanup_by_pid($pid);
	}
}

sub main
{
	my $pm = Parallel::ForkManager->new($max_forks); # number of parallel processes

	$pm->run_on_wait(\&dismiss_hung_workers, 1); # 1 second between callback invocations

	$pm->run_on_finish(sub { 
		my ($pid, $tid) = @_;
		cleanup_by_threadid($tid);
         });

	for my $i (1 .. $total_forks)
	{
		my $pid;

		if ($pid = $pm->start)
		{
			$tids{$i} = $pid;
			$pids{$pid} = $i;
			$workers{$pid} = time();
			next;
		}

		#... do some work with $data in the child process ...
		actually_do_something($i);

		$pm->finish($i); # Terminates the child process
		cleanup_by_threadid($i);
	}
	$pm->wait_all_children;
}

&main;
