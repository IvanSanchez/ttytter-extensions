#  ----------------------------------------------------------------------------
#  "THE BEER-WARE LICENSE":
#  <ivan@sanchezortega.es> wrote this file. As long as you retain this notice you
#  can do whatever you want with this stuff. If we meet some day, and you think
#  this stuff is worth it, you can buy me a beer in return.
#  ----------------------------------------------------------------------------
# 
# Auto-unfollowing of people who tweet a trending topic. Because I liked them until they became popular.
#
# This is heavily based on autounfollow.pl, but is fully automatic. Will refresh the trending topics on every ttytter heartbeat.


my @trendkillers;


use Text::ParseWords;
use Data::Dumper qw{Dumper};


$heartbeat = sub{
	our $trendurl;
	our $verbose;
	
	my $t;
	my $r = &grabjson("$trendurl", 0, 1);

#{"as_of":1237580149,"trends":{"2009-03-20 20:15:49":[{"query":"#sxsw OR SXSW",
	if (defined($r) && ref($r) eq 'HASH' && ($t = $r->{'trends'})){
		
		@trendkillers = ();
		
		my $i;
		my $j;

# 		print $stdout "${EM}<<< TRENDING TOPICS >>>${OFF}\n";
		# this is moderate paranoia
		foreach $i (sort { $b cmp $a } keys %{ $t }) {
			foreach $j (@{ $t->{$i} }) {		
# 				my $k = &descape($j->{'query'});
				my $k = $j->{'query'};
# 				my $l = ($k =~ /\sOR\s/) ? $k :
# 					($k =~ /^"/) ? $k :
# 					('"' . $k . '"');
# 				print $stdout "/search $l\n";
# 				$k =~ s/\sOR\s/ /g;
# 				$k = '"' . $k . '"' if ($k =~ /\s/
# 					&& $k !~ /^"/);
# 				print $stdout "/tron $k\n";
				
				if ($k =~ m/^".*"$/)
				{
					$k =~ s/^"//;
					$k =~ s/"$//;
				}
				
				push(@trendkillers,$k);
			}
			last; # emulate old trends/current behaviour
		}
		print $stdout "-- Hipstter just reloaded new stuff you no longer like (@trendkillers).\n" if ($verbose);
		print Dumper(@trendkillers) if ($verbose);
	} else {
		print $stdout "-- Error: Hipstter doesn't know what you no longer like.\n" if ($verbose);
	}
	return 0;
};


# 
# $addaction = sub {
# 	my $command = shift;
# 
# 	if ($command =~ s#^/killword ## && length($command)) 
# 	{
# 		@killwords = shellwords($command);
# 		
# 		print ("-- Auto-unfollow armed and ready. \n" );
# 		
# 		foreach (@killwords) {
# 			print "-- Auto-unfollow killword active: $_\n";
# 		}
# 		
# 		return 1;
# 	}
# 	else
# 	{
# 		if ($command =~ m/^\/killword$/)
# 		{
# 			$killwords = {};
# 			print ("-- Auto-unfollow is now disarmed.\n" );
# 			return 1;
# 		}
# 	}
# 	return 0;
# };
# 



$handle = sub {
	our $verbose;
	our $leaveurl;
	my $tweet = shift;

	my $text = $tweet->{'text'};

	# This is a VERY UGLY HACK for fixing some encoding issues. Hope it won't break.
	$text =~ s/\\u([a-fA-F0-9][a-fA-F0-9])([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($2))/eg;

	
	print Dumper($text) if ($verbose);
	
	foreach (@trendkillers) {
		my $killword = quotemeta($_);	# This prevents strings with spaces and backslashes and so from being interpreted as regexps.
		
		print "-- Searching for killtrend: $_ ($killword)\n" if ($verbose);
# 		print Dumper($_) if ($verbose);
# 		print Dumper($killword) if ($verbose);
		
		if ($text =~ m/$killword/i)
		{
			print "-- I'm unfollowing ",$tweet->{'user'}->{'screen_name'}," because I liked $_ before he did (I'm such a hipstter).\n";
# 			Username, interactive, baseurl, verb
			&foruuser($tweet->{'user'}->{'screen_name'}, 1, $leaveurl, 'stopped');
			return 0;
		}
		
	}
	
# 	print "-- Tweet not killtrended\n" if ($verbose);
	
	&defaulthandle($tweet);
	return 1;
};






