#!/usr/bin/perl

use strict;

# Variables
my $root_dir = '/weathermap';
my $conf_dir = $root_dir . '/configs';
my $exec_dir = $root_dir . '/myscript';
my $ficlog = $exec_dir . '/log/create_weathermaps.log';
my $ficconf = $exec_dir . '/myscript.conf';
my $weathermap_bin = 'weathermap';
my $cacti_path_rra = '/var/www/localhost/htdocs/cacti/rra';
my $web_path = '/var/www/localhost/htdocs/weathermap';
my $web_path_relative = '/weathermap/';
my $thumb_size = 300;
my $html_file = $web_path . '/' . 'index.html';
my $css_name = 'index.css';
my $js_name = 'index.js';
my $css_file = $web_path . '/' . $css_name;
my $js_file = $web_path . '/' . $js_name;
my $debug=0;

# Globals
my %myfiles;
my %mygroups;

# Print timestamp line into logfile
sub printLog {
   my ($text) = @_;

   open(LOG,">>$ficlog") or die("$0: unable to open logfile $ficlog $!\n");
   print LOG localtime() . " : $text\n";
   close LOG;
}

# Initialize log file
sub startLog {
  open(LOG,">$ficlog") or die("$0: unable to open logfile $ficlog $!\n");
	print LOG localtime() . " : Start Weathermaps Script\n";
	close LOG;
}

# Read Script Configuration file and store entries informations
sub readConf() {
	if ($debug) { printLog('Analyzing Configuration File'); }
	my $cpt=0;
	open(CONF,"$ficconf") or die("$0: unable to open configuration file $ficconf $!\n");
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
			$myfiles{$cf} = \%hashCF;
			$cpt++;
		}
	}
	close CONF;
	if ($debug) { printLog('Configuration files to process : ' . $cpt); }
}

# Create CSS file
sub printCSS() {
	open(CSS,">$css_file") or die("$0: unable to open cssfile $css_file $!\n");
	print CSS 'div.photo {padding:5px; float:left; text-align:center}' . "\n";
	print CSS 'div.caption {text-align:center; width:auto; border-bottom:1px solid #000; padding:3px; background-color:#ffe5e5}' . "\n";
	print CSS 'p.text {display:inline}' . "\n";
	print CSS 'img {border:1px solid #ddd}' . "\n";
	close CSS;
}

# Create JS file
sub printJS() {
	open(JS,">$js_file") or die("$0: unable to open jsfile $js_file $!\n");
	print JS 'function openTab(mytab) { var i; var x = document.getElementsByClassName("mytab"); for (i = 0; i < x.length; i++) { x[i].style.display = "none"; } document.getElementById(mytab).style.display = "block"; }';
	close JS;
}

sub main {
	startLog();
	readConf();
	# Change dir to execute weathermap
	chdir $root_dir;
	foreach my $base (sort keys %myfiles) {
		# If the configuration is enabled
		if ($myfiles{$base}{enable}) {
			my $full_conf_path = $conf_dir . '/' . $base;
			my $full_web_path = $web_path . '/' . $base;
			printLog('Processing ' . $base);
			# Prepare weathermap command
			my $cmd_php = 'php ' . $weathermap_bin . ' --define cacti_path_rra=' . $cacti_path_rra . ' --htmloutput ' . $full_web_path . '.html --output ' . $full_web_path . '.png --image-uri ' . $web_path_relative . $base . '.png --config ' . $full_conf_path . '.conf';
			# Prepapre convert (imagemagick) command to create thumbnail
			my $cmd_thumb = 'convert -thumbnail ' . $thumb_size . ' '. $full_web_path . '.png ' . $full_web_path . '.thumb.png';
			if ($debug) { printLog('Weathermap Command for ' . $base . ' : ' . $cmd_php); }
			my $res_php = system($cmd_php);
			if (!$res_php) { printLog($base . ' : Weathermap created'); }
			else { printLog('!!! ' . $base . ' : Error creating weathermap'); }
			if ($debug) { printLog('Thumbnail Command for ' . $base . ' : ' . $cmd_thumb); }
			my $res_thumb = system($cmd_thumb);
			if (!$res_thumb) { printLog($base . ' : Thumbnail created'); }
			else { printLog('!!! ' . $base .' : Error creating thumbnail'); }
			# Create Map with group name as key
			my $grp = $myfiles{$base}{group};
			push (@{$mygroups{$grp}},$base);
		} else { if ($debug) { printLog('Configuration file ' . $base . ' is disabled'); } }
	}
	if ($debug) { printLog('Initialize HTML File'); }
	printCSS();
	printJS();
	open(WEB,">$html_file") or die("$0: unable to open webfile $html_file $!");
	print WEB '<html><head><title>Cacti Weathermaps</title><link rel="stylesheet" href="' . $css_name . '" type="text/css" /><script type="text/javascript" charset="utf-8" src="' . $js_name . '"></script></head><body>';
	print WEB '<div class="bar">';
	# Create the button css bar
	foreach my $grp (sort keys %mygroups) {
		print WEB '<button class="button" onclick="openTab(\'' . $grp . '\')">' . $grp . '</button>';
	}
	print WEB '</div>';
	my $cpt=0;
	foreach my $grp (sort keys %mygroups) {
		print WEB '<div id="' . $grp . '" class="mytab"';
		if ($cpt) { print WEB ' style="display:none"'; }
		print WEB '><h2>' . $grp .'</h2>';
		$cpt++;
		foreach my $base (@{$mygroups{$grp}}) {
			printLog('Creating web entry for ' . $base);
			print WEB '<div class="photo"><a href="' . $base . '.png"><img src="' . $base . '.thumb.png" alt="' . $myfiles{$base}{name} . '"></a><div class="caption"><p class="text">' . $myfiles{$base}{name} . '</p></div></div>';
		}
		print WEB '</div>';
	}
	print WEB '</body></html>';
	close WEB;
	chdir $exec_dir;
}

main();
