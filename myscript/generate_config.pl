#!/usr/bin/perl

use strict;

# Variables
my $root_dir = '/weathermap';
my $conf_dir = $root_dir . '/configs';
my $exec_dir = $root_dir . '/myscript';
my $ficconf = $exec_dir . '/myscript.conf';

# Global
my @conf_files;
my %existing;

# List and store weathermap configuration files names
sub list_conf_files() {
	opendir(DIR,"$conf_dir") or die "$0: $conf_dir is not accessible $!\n";
	@conf_files = readdir(DIR);
	closedir DIR;
}

# Read script configuration file and store previous entries
sub read_ficconf() {
	open(CONF,"$ficconf") or die "$0: $ficconf is not readable $!\n";
	while (<CONF>) {
		chomp;
		my $line = $_;
		if (substr($line,0,1) ne '#') {
			my ($cf,$ena,$grp,$name) = split(/;/,$line,4);
			if ($ena eq '') { $ena = 1; }
			if ($grp eq '') { $grp = 'Default'; }
			if ($name eq '') { $name = $cf; }
			my %hashCF = (
				enable => $ena,
				group => $grp,
				name => $name,
			);
			$existing{$cf} = \%hashCF;
		}
	}
	close CONF;
}

sub main {
	# If existing read script configuration file, list weathermap files and initialize new script configuration file
	if (-e $ficconf) { read_ficconf(); }
	list_conf_files();
	open(CONF,">$ficconf") or die "$0: $ficconf is not writable $!\n";
	print CONF "# Configuration file for weathermap script, one line per weatermap configuration file\n";
	print CONF "# Four parameters separated with ;\n";
	print CONF "# 1: Filename without suffix\n";
	print CONF "# 2: Enable 1=Yes, 2=No\n";
	print CONF "# 3: Group Name if none defaults to Default\n";
	print CONF "# 4: Weathermap Name to display in webpage, default to filename\n";
	print CONF "# Example: LAN;1;myGroup;my LAN map\n";

	# Cycle through weathermap files
	foreach my $file (@conf_files) {
		# Collect only conf files and take filename without suffix
		if ($file =~ /.+\.conf/) {
			my $base = $file;
			$base =~ s/\.conf//;
			# If already existing configuration, reprint it else print with default parameters
			if (exists $existing{$base}) {
				print CONF $base . ';' . $existing{$base}{enable} . ';' . $existing{$base}{group} . ';' . $existing{$base}{name} . "\n";
			} else { print CONF "$base;1;Default;$base\n"; }
		}
	}
	close CONF;
}

main();
