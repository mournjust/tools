#!/usr/bin/perl -w
use strict;
my $file = shift @ARGV;
if (!open(MYFILE, $file)) {
	die "Can't open file sdm660_global.txt\n";
}

while (<MYFILE>) {
	chomp;
	if ( m/global_dirty_state: dirty\=(\d+)/g ) {
		print "$1\n";
	}
}
close(MYFILE);
