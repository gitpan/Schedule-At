# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Schedule::At;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

listJobs('Initial state');
print "ok 2\n";

my $rv;

$rv = Schedule::At::add (
	TIME => '199801181530', 
	COMMAND => 'ls', 
	TAG => 'Schedule::At'
);
listJobs('Added new job');
print "not " if $rv;
print "ok 3\n";

my %atJobs = Schedule::At::getJobs();
print "not " if !defined(%atJobs);
print "ok 4\n";

$rv = Schedule::At::remove (TAG => 'Schedule::At');
listJobs('Schedule::At jobs deleted');
print "not " if $rv;
print "ok 5\n";

sub listJobs {
	print STDERR "@_\n" if @_;
	my %atJobs = Schedule::At::getJobs();
	foreach my $job (values %atJobs) {
		print STDERR "\t", $job->{JOBID}, "\t", $job->{TIME}, ' ', 
			($job->{TAG} || ''), "\n";
	}
}
