#!/usr/bin/perl -w
use strict;
my $file = shift @ARGV;
if (!open(MYFILE, $file)) {
	die "Can't open file sdm660_global.txt\n";
}

while (<MYFILE>) {
	chomp;
	next if ( m/writeback_mark_inode_dirty/g );
	next if ( m/writeback_dirty_inode_start/g );
	next if ( m/writeback_dirty_inode/g );
	print ;	
	print "\n";
}
close(MYFILE);
