package Schedule::At;

require 5.004;

# Copyright (c) 1997,1998 Jose A. Rodriguez. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use vars qw($VERSION @ISA $TIME_FORMAT);

use AutoLoader 'AUTOLOAD';
@ISA = qw(AutoLoader);

$VERSION = '1.02';

###############################################################################
# Load configuration for this OS
###############################################################################

use Config;

my @configs = split (/\./, "$Config{'osname'}.$Config{'osvers'}");

while (@configs) {
	my $subName = 'AtCfg_' . join('_', @configs);
	$subName =~ tr/./_/;

	eval "&$subName"; # Call configuration subroutine
	last if !$@; 

	pop @configs;
}

&AtCfg if $@; # Default configuration

###############################################################################
# Public subroutines
###############################################################################

$TIME_FORMAT = '%Q%H%M'; # Format for Date::Manip::DateUnix subroutine

$TAGID = '##### Please, do not remove this Schedule::At TAG: ';

sub add {
	my %params = @_;

	my $command = $AT{($params{FILE} ? 'addFile' : 'add')};
	return &$command($params{JOBID}) if ref($command) eq 'CODE';

	my $atTime = std2atTime($params{TIME});
	
	$command =~ s/%TIME%/$atTime/g;
	$command =~ s/%FILE%/$params{FILE}/g;

	if ($params{FILE}) {
		return (system($command) / 256);
	} else {
		open (ATCMD, "| $command") or return 1;
		print ATCMD "$TAGID$params{TAG}\n" if $params{TAG};
		print ATCMD $params{COMMAND};
		close (ATCMD);
	}

	0;
}

sub remove {
	my %params = @_;

	if ($params{JOBID}) {
		my $command = $AT{'remove'};
		return &$command(@_) if ref($command) eq 'CODE';

		$command =~ s/%JOBID%/$params{JOBID}/g;

		system($command) / 256;
	} else {
		return if !defined $params{TAG};

		my %jobs = getJobs();

		foreach my $job (values %jobs) {
			next if !defined($job->{JOBID}) || 
				!defined($job->{TAG});

			remove (JOBID => "$job->{JOBID}") 
				if $job->{JOBID} && $params{TAG} eq $job->{TAG};
		}
	}
}

sub getJobs {
	my %jobs;
	
	my $command = $AT{'getJobs'};
	return &$command(@_) if ref($command) eq 'CODE';

	open (ATCMD, "$command |")
		or return undef;
	line: while (defined (my $atLine = <ATCMD>)) {
		if (defined $AT{'headings'}) {
			foreach my $head (@{$AT{'headings'}}) {
				next line if $atLine =~ /$head/;
			}
		}

		chomp $atLine;

		my %atJob;
		($atJob{JOBID}, $atJob{TIME}) 
			= &{$AT{'parseJobList'}}($atLine);
		$atJob{TAG} = getTag (JOBID => $atJob{JOBID});
		$jobs{$atJob{JOBID}} = \%atJob;
	}
	close (ATCMD);

	return %jobs;
}

###############################################################################
# Private subroutines
###############################################################################

sub getTag {
	my %params = @_;

	my $command = $AT{'getCommand'};
	$command = &$command($params{JOBID}) if ref($command) eq 'CODE';

	$command =~ s/%JOBID%/$params{JOBID}/g;

	my $tag;

	open (GETTAG, "$command")
		or die "Can't open $command: $!\n";
	while (defined (my $commandLine = <GETTAG>)) {
		return $1 if $commandLine =~ /$TAGID(.*)$/;
	}
	close (GETTAG);

	undef;
}

sub std2atTime {
	my ($stdTime) = @_;

	# StdTime: YYYYMMDDHHMM
	my ($year, $month, $day, $hour, $mins) = 
		$stdTime =~ /(....)(..)(..)(..)(..)/;

	my $timeFormat = $AT{'timeFormat'};	
	return &$timeFormat($year, $month, $day, $hour, $mins) 
		if ref($timeFormat) eq 'CODE';

	$timeFormat =~ s/%YEAR%/$year/g;
	$timeFormat =~ s/%MONTH%/$month/g;
	$timeFormat =~ s/%DAY%/$day/g;
	$timeFormat =~ s/%HOUR%/$hour/g;
	$timeFormat =~ s/%MINS%/$mins/g;

	$timeFormat;
}

__END__

=head1 NAME

Schedule::At - OS independent interface to the Unix 'at' command

=head1 SYNOPSIS

 require Schedule::At;

 Schedule::At::add(TIME => $string, COMMAND =>$string [, TAG =>$string]);
 Schedule::At::add(TIME => $string, FILE => $string [, TAG => $string])

 Schedule::At::remove(JOBID => $string);
 Schedule::At::remove(TAG => $string);

 %jobs = Schedule::At::getJobs();

=head1 DESCRIPTION

This modules provides an OS independent interface to 'at', the Unix 
command that allows you to execute commands at a specified time.

=over 4

=item Schedule::At::add

Adds a new job to the at queue. 

You have to specify a B<TIME> and a command to execute. The B<TIME> has
a common format: YYYYMMDDHHmm. Where B<YYYY> is the year (4 digits), B<MM>
the month (01-12), B<DD> is the day (01-31), B<HH> the hour (00-23) and
B<mm> the minutes.

The command is passed with the B<COMMAND> or the B<FILE> parameter.
B<COMMAND> can be used to pass the command as an string, and B<FILE> to
read the commands from a file.

The optional parameter B<TAG> serves as an application specific way to 
identify a job or a set of jobs.

Returns 0 on success or a value != 0 if an error occurred.

=item Schedule::At::remove

Remove an at job.

You identify the job to be deleted using the B<JOBID> parameter (an 
opaque string returned by the getJobs subroutine). You can also specify
a job or a set of jobs to delete with the B<TAG> parameter, removing
all the jobs that have the same tag (as specified with the add subroutine).

Returns 0 on success or a value != 0 if an error occurred.

=item Schedule::At::getJobs

Returns a hash with all the current jobs or undef if an error occurred. 
For each job the key is a JOBID (an OS dependent string that shouldn't be 
interpreted), and the value is a hash reference. 

This hash reference points to a hash with the keys:

=over 4

=item TIME

An OS dependent string specifying the time to execute the command

=item TAG

The tag specified in the Schedule::At::add subroutine

=back

=back

=head1 EXAMPLES

 use Schedule::At;

 # 1
 Schedule::At::add (TIME => '199801181530', COMMAND => 'ls', 
	TAG => 'ScheduleAt');
 # 2
 Schedule::At::add (TIME => '199801181630', COMMAND => 'ls', 
	TAG => 'ScheduleAt');
 # 3
 Schedule::At::add (TIME => '199801181730', COMMAND => 'ls');

 # This will remove #1 and #2 but no #3
 Schedule::At::remove (TAG => 'ScheduleAt');

 my %atJobs = Schedule::At::getJobs();
 foreach my $job (values %atJobs) {
	print "\t", $job->{JOBID}, "\t", $job->{TIME}, ' ', 
		($job->{TAG} || ''), "\n";
 } 

=head1 AUTHOR

Jose A. Rodriguez (josear@ac.upc.es)

=cut

###############################################################################
# OS dependent code
###############################################################################

sub AtCfg {
	# Currently the default configuration just aborts
	die "There is no config for this OS";
}

sub AtCfg_solaris {
	$AT{'add'} = 'at %TIME% 2> /dev/null';
	$AT{'addFile'} = 'at -f %FILE% %TIME% 2> /dev/null';
	$AT{'timeFormat'} = sub { 
		my ($year, $month, $day, $hour, $mins) = @_;

		my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
			'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

		"$hour:$mins " . $months[$month-1] . " $day, $year";
	};
	$AT{'remove'} = 'at -r %JOBID%';
	$AT{'getJobs'} = 'at -l';
	$AT{'headings'} = [];
	$AT{'getCommand'} = '/usr/spool/cron/atjobs/%JOBID%';
	$AT{'parseJobList'} = sub { $_[0] =~ /^\s*(\S+)\s+(.*)$/ };
}

sub AtCfg_sunos {
	&AtCfg_solaris;
	$AT{'getCommand'} = sub {
		my ($jobid) = @_;

		for my $filename (glob('/usr/spool/cron/atjobs/*')) {
			return $filename if (stat($filename))[1] == $jobid;
		}

		undef;
	}
}

sub AtCfg_dec_osf {
	&AtCfg_solaris;
}

sub AtCfg_hpux {
	$AT{'add'} = 'at %TIME% 2> /dev/null';
	$AT{'addFile'} = 'at -f %FILE% %TIME% 2> /dev/null';
	$AT{'timeFormat'} = '%HOUR%:%MINS% %MONTH%/%DAY%/%YEAR%';
	$AT{'remove'} = 'at -r %JOBID%';
	$AT{'getJobs'} = 'at -l';
	$AT{'headings'} = [];
	$AT{'getCommand'} = '/usr/spool/cron/atjobs/%JOBID%';
	$AT{'parseJobList'} = sub { $_[0] =~ /^(\S+)\s+(.*)$/ };
}

sub AtCfg_linux {
	$AT{'add'} = 'at %TIME% 2> /dev/null';
	$AT{'addFile'} = 'at -f %FILE% %TIME% 2> /dev/null';
	$AT{'timeFormat'} = '%HOUR%:%MINS% %MONTH%/%DAY%/%YEAR%';
	$AT{'remove'} = 'atrm %JOBID%';
	$AT{'getJobs'} = 'atq';
	$AT{'headings'} = ['Date'];
	$AT{'getCommand'} = 'at -c %JOBID% |';
	$AT{'parseJobList'} = 
		sub { (substr($_[0], 27), substr($_[0], 0, 17)) } ;
}
