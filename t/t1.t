use Test;

BEGIN { plan tests => 6 }

my $verbose = 0;

use Schedule::At;
ok(1);

my $rv;

my $nextYear = (localtime)[5] + 1901;

listJobs('Init state') if $verbose;
my %beforeJobs = Schedule::At::getJobs();

$rv = Schedule::At::add (
	TIME => $nextYear . '01181530', 
	COMMAND => 'ls /thisIsACommand/', 
	TAG => '_TEST_aTAG'
);
my %afterJobs = Schedule::At::getJobs();

listJobs('Added new job') if $verbose;
ok(!$rv && ((scalar(keys %beforeJobs)+1) == scalar(keys %afterJobs)));

my %atJobs = Schedule::At::getJobs();
ok(%atJobs);

my ($jobid, $content) = Schedule::At::readJobs(TAG => '_TEST_aTAG');
ok($content, '/thisIsACommand/');

$rv = Schedule::At::remove (TAG => '_TEST_aTAG');
my %afterRemoveJobs = Schedule::At::getJobs();
listJobs('Schedule::At jobs deleted') if $verbose;
ok(!$rv && scalar(keys %beforeJobs) == scalar(keys %afterRemoveJobs));

# getJobs with TAG param
$rv = Schedule::At::add (
	TIME => $nextYear . '01181531', 
	COMMAND => 'ls /cmd1/',
	TAG => '_TEST_tag1'
);
$rv = Schedule::At::add (
	TIME => $nextYear . '01181532', 
	COMMAND => 'ls /cmd2/',
	TAG => '_TEST_tag2'
);

my %tag1Jobs = Schedule::At::getJobs(TAG => '_TEST_tag1');
my %tag2Jobs = Schedule::At::getJobs(TAG => '_TEST_tag2');
listJobs('Schedule::At tag1 and tag2 added') if $verbose;
ok(join('', map { $_->{TAG} } values %tag1Jobs), '/^(_TEST_tag1)+$/');
$rv = Schedule::At::remove (TAG => '_TEST_tag1');
$rv = Schedule::At::remove (TAG => '_TEST_tag2');
listJobs('Schedule::At tag1 and tag2 removed') if $verbose;

sub listJobs {
	print STDERR "@_\n" if @_;
	my %atJobs = Schedule::At::getJobs();
	foreach my $job (values %atJobs) {
		print STDERR "\tID:$job->{JOBID}, Time:$job->{TIME}, Tag:",
			($job->{TAG} || ''), "\n";
	}
}
