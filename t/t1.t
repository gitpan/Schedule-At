use Test;

BEGIN { plan tests => 4 }

my $verbose = 0;

use Schedule::At;
ok(1);

my $rv;

my $nextYear = (localtime)[5] + 1901;

listJobs('Init state') if $verbose;
my %beforeJobs = Schedule::At::getJobs();

$rv = Schedule::At::add (
	TIME => $nextYear . '01181530', 
	COMMAND => 'ls', 
	TAG => 'Schedule::At'
);
my %afterJobs = Schedule::At::getJobs();

listJobs('Added new job') if $verbose;
ok(!$rv && ((scalar(keys %beforeJobs)+1) == scalar(keys %afterJobs)));

my %atJobs = Schedule::At::getJobs();
ok(%atJobs);

$rv = Schedule::At::remove (TAG => 'Schedule::At');
my %afterRemoveJobs = Schedule::At::getJobs();
listJobs('Schedule::At jobs deleted') if $verbose;
ok(!$rv && scalar(keys %beforeJobs) == scalar(keys %afterRemoveJobs));

sub listJobs {
	print STDERR "@_\n" if @_;
	my %atJobs = Schedule::At::getJobs();
	foreach my $job (values %atJobs) {
		print STDERR "\tID:$job->{JOBID}, Time:$job->{TIME}, Tag:",
			($job->{TAG} || ''), "\n";
	}
}
