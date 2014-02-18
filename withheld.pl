# Shows up a bit of readable info about withheld tweets

$eventhandle = sub {
  $event = shift;

  if (defined $event->{'status_withheld'})
  {
    $tweet_id  = $event->{'status_withheld'}->{'id'};
    $user_id   = $event->{'status_withheld'}->{'user_id'};
    $countries = $event->{'status_withheld'}->{'withheld_in_countries'}; # Array

    $countries_text = join (', ', @countries);
    if (!$countries_text eq '')
    {
        $countries_text = ' in ' . $countries_text;
    }

    &$exception(40,"--- Tweet $tweet_id by user $user_id has been withheld$countries_text.\n");
  }

  &defaulteventhandle($event);

  return 1;

}
