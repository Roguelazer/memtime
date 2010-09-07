#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Time::HiRes qw(usleep time);

use constant PAGE_SIZE=>4096;

my $verbose = 0;
# Number of microseconds to sleep for
my $interval = 100000; # 0.1 seconds--ish

sub monitor_pid($) {
    my $pid = shift;
    my $data = [];
    unless ($pid) {
        die("No PID specified")
    }
    while (-d "/proc/$pid/") {
        my $STAT;
        open ($STAT, "</proc/$pid/stat") or last;
        my @stat = split /\s+/, <$STAT>;
        close($STAT);
        my $vsz = $stat[22];
        my $rss = $stat[23] * PAGE_SIZE;
        push(@$data, (time(), $vsz, $rss));
        usleep($interval);
    }
    return $data;
}

sub print_csv($$) {
    my $data_ref = shift;
    my $output = shift;
    my $OUTPUT;
    if ($output) {
        open($OUTPUT, ">$output");
    }
    my $nentries = scalar @{$data_ref};
    for (my $i = 0; $i < $nentries; $i += 3) {
        my $time = $data_ref->[$i];
        my $vsz = $data_ref->[$i+1];
        my $rss = $data_ref->[$i+2];
        if ($OUTPUT) {
            print {$OUTPUT } "$time,$vsz,$rss\n";
        }
        else {
            print "$time,$vsz,$rss\n";
        }
    }
    if ($OUTPUT) {
        close($OUTPUT);
    }
}

sub main() {
    my $help = 0;
    my $man = 0;
	my $opt_interval = 0;
    my $argc = $#ARGV + 1;
    my $output = '';
    GetOptions('help|?' => \$help,
        'man' => \$man,
        'verbose' => \$verbose,
		'interval=i' => \$opt_interval,
        'output=s' => \$output) or pod2usage(2);
    pod2usage(1) if $help or ($argc < 1);
    pod2usage(-exitstatus => 0, -verbose=>2) if $man;
	if ($opt_interval > 0) {
		$interval = $opt_interval;
	}
    # See if we're in PID mode
    if ($argc == 1 && $ARGV[0] =~ /^\d+$/) {
        my $data = monitor_pid(int($ARGV[0]));
        print_csv($data, $output);
    }
    else {
        my $pid = fork();
        if ($pid == 0) {
            if ($verbose) {
                printf("Executing `%s`\n", join(" ", @ARGV));
            }
            exec { $ARGV[0] } @ARGV;
            die("Error execing");
        }
        else {
            my $innerpid = fork();
            if ($innerpid == 0) {
                my $data = monitor_pid($pid);
                print_csv($data, $output);
                exit(0);
            }
            else {
                my $status = waitpid($pid, 0);
                if ($verbose) {
                    printf("Process exited with status %d\n", $?);
                }
                waitpid($innerpid, 0);
            }
        }
    }
}

main()

__END__
=head1 NAME

sample_memory_usage: Get the memory usage stats for a process

=head1 SYNOPSIS

sample_memory_usage [options] (PID | command)

  Options:
    --help          Brief help message
    --man           Full documentation
    --verbose       Be talkative
    --output FILE   Write output to FILE
    --interval INT  Sample every INT microseconds (default 100000)

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exit

=item B<--man>

Print the man page and exit

=item B<--verbose>

Be more verbose!

=item B<--output I<FILE>>

Write output to I<FILE> instead of stdout

=item B<--interval I<INT>>

Sample data every I<INT> microseconds (default 100000 = 0.1 seconds)

=back

=head1 DESCRIPTION

B<sample_memory_usage> takes either a PID or a command to execute and
samples periodically to collect memory usage stats. Somewhat similar to
time(1), but in more detail. Use with graph-memory-usage(1) to produce
prettified output.

=head1 BUGS

=over 4

=item *

Assumes page size is always 4k instead of checking like a reasonable program ought to.

=item *

Isn't terribly good at handling programs that exit quickly (may infinite-loop). Don't do that.

=back

=head1 AUTHOR

James Brown <jbrown@yelp.com>

=head1 SEE ALSO

graph-memory-usage(1), time(1)

=cut
