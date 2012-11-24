#  ----------------------------------------------------------------------------
#  "THE BEER-WARE LICENSE":
#  <ivan@sanchezortega.es> wrote this file. As long as you retain this notice you
#  can do whatever you want with this stuff. If we meet some day, and you think
#  this stuff is worth it, you can buy me a beer in return.
#  ----------------------------------------------------------------------------
# 
# Auto-unfollowing of people who tweet a killword.
#
# This extension allows you to unfollow anyone that refers to certain prohibited words, or "killwords". 
#
# It defines a new command, /killword. Use it to specify which killword or killwords will be searched for in every tweet; for example:
#
#  /killword "Please RT" viagra
#
# Defining a set of killwords will overwrite the previous set of killwords.
#
# If a tweet contains *any* of the killwords, then:
#  * You will unfollow the sender
#  * The tweet will be filtered (buggy!)
#


my @killwords;


use Text::ParseWords;


$addaction = sub {
	my $command = shift;

	if ($command =~ s#^/killword ## && length($command)) 
	{
		@killwords = shellwords($command);
		
		print ("-- Auto-unfollow armed and ready. \n" );
		
		foreach (@killwords) {
			print "-- Auto-unfollow killword active: $_\n";
		}
		
		return 1;
	}
	else
	{
		if ($command =~ m/^killword$/)
		{
			$killwords = {};
			print ("-- Auto-unfollow is now disarmed.\n" );
		}
	}
	return 0;
};




$handle = sub {
	our $verbose;
	our $leaveurl;
	my $tweet = shift;

	my $text = $tweet->{'text'};

	foreach (@killwords) {
		my $killword = quotemeta($_);	# This prevents strings with spaces and backslashes and so from being interpreted as regexps.
		
		print "-- Searching for killword: $_\n" if ($verbose);
		if ($text =~ m/$killword/i)
		{
			print "-- Found tweet from ",$tweet->{'user'}->{'screen_name'}," with killword: $_\n";
# 			Username, interactive, baseurl, verb
			&foruuser($tweet->{'user'}->{'screen_name'}, 1, $leaveurl, 'stopped');
			return 0;
		}
		
	}
	
	print "-- Tweet not killworded\n" if ($verbose);
	
	&defaulthandle($tweet);
	return 1;
};






