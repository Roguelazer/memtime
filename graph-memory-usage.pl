#!/usr/bin/perl

use strict;
use warnings;
use Switch;
use FileHandle;
use Getopt::Long;
use Pod::Usage;

my $help = 0;
my $man = 0;
my $argc = $#ARGV + 1;
GetOptions('help|?' => \$help,
    'man' => \$man) or pod2usage(2);
pod2usage(1) if $help or ($argc < 1);
pod2usage(-exitstatus => 0, -verbose=>2) if $man;
pod2usage(1) if ($argc < 2);

my $datafile = $ARGV[0];
my $outfile = $ARGV[1];
my $labelsfile = $ARGV[2];
my $labelsfileout;
if ($labelsfile) {
    $labelsfileout = $labelsfile . ".out";   
}
my $max = 0;
my $min = 1000000;
my @labels = ();
open(DF, "<$datafile");
while (<DF>) {
    my @data = split(/,/);
    if ($data[1] > $max) {
        $max = $data[1];
    }
    if ($data[1] < $min) {
        $min = $data[1];
    }
}
close(DF);
$max /= 1024;
$min /= 1024;
if ($labelsfile) {
    open(LF, "<$labelsfile");
    open(LFP, ">$labelsfileout");
    my $count = 0;
    while(<LF>) {
        my @data = split(/,/);
        my $height;
        switch ($count % 3) {
            case 0 {
                $height = $max * 1.02;
            }
            case 1 {
                $height = $max * 1.06;
            }
            case 2 {
                $height = $max * 1.10;
            }
        }
        print LFP "$data[0],$height,$data[1]\n";
        push(@labels, int($data[0]));
        $count += 1;
    }
    close(LFP);
    close(LF);
}

open(my $GP, "|/usr/bin/gnuplot -persist") or die "no gnuplot";
$GP->autoflush(1);
print {$GP} "set term postscript color\n";
print {$GP} "set out '$outfile'\n";
print {$GP} "set datafile separator ','\n";
print {$GP} "set title '$datafile'\n";
print {$GP} "set xlabel 'Time'\n";
print {$GP} "set ylabel 'Memory Usage (kB)'\n";
print {$GP} "set key below\n";
for my $label (@labels) {
    print {$GP} "set arrow from $label,$min to $label,$max nohead lw 0.1\n";
}
#print {$GP} "set xdata time\n";
#print {$GP} "set timefmt \"%s\"\n";
#print {$GP} "set format x \"%H:%M:%S\"\n";
print {$GP} "plot '$datafile' using 1:(\$2/1024) title 'vsz' with lines, '$datafile' using 1:(\$3/1024) title 'rss' with lines";
if ($labelsfile) {
    print {$GP} ", '$labelsfileout' using 1:2:3 with labels font \"Courier,8\" notitle";
}
else {
    print {$GP} "\n";
}
close($GP);
if ($labelsfile) {
    unlink($labelsfileout);
}
__END__
=encoding utf8

=head1 NAME

graph-memory-usage: graph memory usage for a process

=head1 SYNOPSIS

graph-memory-usage F<data_file> F<output_file> [F<label_file>]

  Options:
    --help          Brief help message
    --man           Full documentation

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exit

=item B<--man>

Print the man page and exit

=back

=head1 DESCRIPTION

B<graph-memory-usage> produces prettified output from sample_memory_usage(1). It takes
three arguments: a data file (as output by sample_memory_usage), the name of the file to
write to (should be a .ps), and (optionally) another file containing labels.

The format of the data file is CSV with three columns. The first column should be a
Unix timestamp. The second should be the VSZ at that time. The third should be the RSS
at that time. All sizes should be in bytes.

The format of the label file is CSV with two columns. The first column should be a Unix timestamp.
The second should be the label (string-escaped and double-quoted) to place at that time.

=head1 EXAMPLE

=head2 DATA FILE

 1280890106.0,1024,512
 1280890106.5,1024,512
 1280890107.0,1536,1024
 1280890107.5,1536,1102
 1280890108.0,2048,1134
 1280890108.5,2242,1020

=head2 LABEL FILE

 1280890107.2,"thing 1 started"
 1280890108.1,"thing 2 started"

=head2 OUTPUT

(output is approximated by the "dumb" terminal setting in gnuplot; will actually be a PostScript file)

                                      test.csv
  Memory Usage (kB)
    2.4 ++------------+------------+-------------+------------+------------++
        +             +           thing 1 started+        thing 2 started   +
    2.2 ++                         >                          >      ********
      2 ++                         >                         *>******      ++
        |                          >                      *** >             |
    1.8 ++                         >                  ****    >            ++
    1.6 ++                         >               ***        >            ++
        |                         *>***************           >             |
    1.4 ++                     *** >                          >            ++
        |                  ****    >                          >             |
    1.2 ++              ***        >                    ######>#############+
      1 ****************          #>####################      >            +#
        |                      ###                                          |
    0.8 ++                 ####                                            ++
    0.6 ++              ###                                                ++
        ################           +             +            +             +
    0.4 ++------------+------------+-------------+------------+------------++
   1.28089e+09   1.28089e+09  1.28089e+09   1.28089e+09  1.28089e+091.28089e+09
                                        Time

=head1 BUGS

=over 4

=item *

The time should be displayed as actual time instead of Unix timestamp. Unfortunately,
gnuplot's "set arrow" command doesn't work when using xdata time, so I'd have to draw
the vertical lines in parametric mode, which I don't really care to do.

=back

=head1 AUTHOR

James Brown <jbrown@yelp.com>

=head1 SEE ALSO

sample_memory_usage(1), gnuplot(1)

=cut
