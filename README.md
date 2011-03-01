memtime
=======

Something that's really handy to do is to be able to sample a process's
memory usage over time. [time(1)](http://www.kernel.org/doc/man-pages/online/pages/man1/time.1.html)
can give you some aggregate data (max, min, avg), but what would be great would be
if there were some way to graph it and look when memory spiked. Well, that's the
goal of **memtime**.

Usage
-----
There are two components of **memtime**: *sample-memory-usage* and *graph-memory-usage*. *sample-memory-usage*
actually gathers the data, *graph-memory-usage* uses [gnuplot](http://www.gnuplot.info/) to present it
in a user-friendly manner. Both have man pages accessible with the `--man` flag, including example usage.
