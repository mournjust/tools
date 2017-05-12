#!/usr/bin/perl -w
use strict;
my $file = shift @ARGV;
if (!open(MYFILE, $file)) {
	die "Can't open file ftrace log\n";
}

my $total_time_read = 0;
my $total_sectors_read = 0;
my $total_time_write = 0;
my $total_sectors_write = 0;
my %pending_request = ( );
my $total_requests  = 0;
my $total_read_requests = 0;
my $total_write_requests = 0;

while ( <MYFILE> ) {
	my $start_time = undef;
	my $end_time = undef;
	my $start_sector = undef;
	my $sector_num = undef;
	my $dev_major = undef;
	my $dev_minor = undef;
	my $op = undef;

	my $this_time = undef;
	my $this_len = undef;

	#html format (systrace)
	#mmcqd/1-6736  ( 6736) [006] d..2  3189.434652: block_rq_issue: 179,64 WA 0 () 2602278 + 1024 [mmcqd/1]
	#txt format (ftrace)
	#mmcqd/1-6736  [003] ...1 170740.611877: block_rq_complete: 179,64 RA () 63526 + 1 [0]
	#if (  m/\s*\S+\s+\(\s*\d+\)\s+\S+\s+\S+\s+(\d+)\.(\d+):\sblock_rq_issue:\s(\d+),(\d+)\s*([DWRN])A\s*\d\s*\(\)\s+(\d+)\s+\+\s+(\d+)/g ) {
	if (  m/.*\[\d+\]\s+\S+\s+(\d+)\.(\d+):\sblock_rq_issue:\s(\d+),(\d+)\s*([DWRN])A\s*\d\s*\(\)\s+(\d+)\s+\+\s+(\d+)/g ) {
		$start_time = $1 + $2/1000000;
		next if ($3 != 179 || $4 != 64);
		$op = $5;
		$start_sector = $6;
		$sector_num = $7;
		my %request = ();

		$request{label} = "$start_sector$op";
		$request{start_time} = $start_time;
		$request{len} = $sector_num;
		$pending_request{$request{label}} = \%request;
		$total_requests += 1;
		if ($5 =~ m/R/) {
			$total_read_requests += 1;
		} elsif ($5 =~ m/W/) {
			$total_write_requests += 1;
		}
		#print "start rq $1 $2 $3 $4 $5 $6 $7 \n";
	}

	#mmcqd/1-6736  ( 6736) [006] ...1  3189.430100: block_rq_complete: 179,64 WA () 2601254 + 1024 [0]
	#mmcqd/1-6736  [003] d..2 170741.057671: block_rq_issue: 179,64 RA 0 () 12655878 + 256 [mmcqd/1]
	if (  m/.*\[\d+\]\s+\S+\s+(\d+)\.(\d+): block_rq_complete: (\d+),(\d+)\s+([DWRN])A\s+\(\)\s+(\d+)\s+\+\s+(\d+)/g ) {
		next if ( $3 != 179 || $4 != 64 );

		$end_time = $1 + $2/1000000;
		my $name = "$6$5";

		#print "finish rq $1 $2 $3 $4 $5 $6 $7 \n";
		if ( exists $pending_request{$name} ) {
			my %request = %{$pending_request{$name}};
			#print "find pending request $request{label}, start time = $request{start_time}\n";
			$this_time = $end_time - $request{start_time};
			$this_len = $7;
			if ($5 =~ m/R/) {
				$total_time_read += $this_time;
				$total_sectors_read += $this_len;
			} elsif ($5 =~ m/W/){
				$total_time_write += $this_time;
				$total_sectors_write += $this_len;
			}
			delete $pending_request{$name};
		}
	}
}

my $unhandled_request = keys %pending_request;
if ($unhandled_request != 0) {
	print " $unhandled_request requests not handled\n";
};

print "Total READ time = $total_time_read \n";
print "Total READ sectors = $total_sectors_read \n";
print "Total request: $total_requests, READ: $total_read_requests, WRITE: $total_write_requests\n";
if ($total_time_read != 0) {
	my $speed_read = undef;
	$speed_read = ($total_sectors_read/2)/$total_time_read;
	$speed_read = $speed_read/1024;
	print "READ speed = $speed_read MB/s\n";
};
print "Total WRITE time = $total_time_write \n";
print "Total WRITE sectors = $total_sectors_write \n";
if ($total_time_write != 0) {
	my $speed_write = undef;
	$speed_write = ($total_sectors_write/2)/$total_time_write;
	$speed_write = $speed_write/1024;
	print "WRITE speed = $speed_write MB/s\n";
}
close(MYFILE);

