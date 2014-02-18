# Debug extension to get more details about event data structs


use Data::Dumper qw{Dumper};



$eventhandle = sub {

#  print Dumper($_[0]);

  $event = shift;

  if (defined $event->{'delete'})
  {
    print "--- Somebody deleted something\n";
  }
  elsif ($event->{'event'} eq 'follow')
  {
    print "--- Someone followd someone\n";
  }
  elsif ($event->{'event'} eq 'unfollow')
  {
    print "--- Someone unfollowed someone\n";
  }
  elsif ($event->{'event'} eq 'list_member_added')
  {
    print "--- Someone added someone to a list\n";
  }
  elsif ($event->{'event'} eq 'unfavorite')
  {
    print "--- Someone unfavorited something\n";
  }
  elsif ($event->{'event'} eq 'favorite')
  {
    print "--- Someone favorited something\n";
  }
  elsif (defined $event->{'status_withheld'})
  {
    print "--- A tweet was withheld\n";
  }
  else
  {
      print  Dumper($event);
  }

  &defaulteventhandle($event);

  return 1;

}

