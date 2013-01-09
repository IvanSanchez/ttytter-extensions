#  ----------------------------------------------------------------------------
#  "THE BEER-WARE LICENSE":
#  <ivan@sanchezortega.es> wrote this file. As long as you retain this notice you
#  can do whatever you want with this stuff. If we meet some day, and you think
#  this stuff is worth it, you can buy me a beer in return.
#  ----------------------------------------------------------------------------


# SuperPwntter is an evolution of the original pwntter by Sean Doherty AKA @pr4wn AKA sean dot prawn at gmail dot com.
# SuperPwntter logs all data about all seen tweets into several MySQL tables.

# CPAN Modules
use DBI;
use Date::Manip;
use HTML::Entities;

use Data::Dumper qw{Dumper};

use URI::Split qw(uri_split uri_join);

use Digest::MD5  qw(md5 md5_hex md5_base64);




# mysql database config
my $host     = "localhost";
my $db	     = "pwntter";
my $user_id  = "pwntter";
my $password = "pwntter";
my $pwntter_version = "0.3";

sub date_format {
  my $date = shift;
  my $s;
  if (! defined $date) {exit};
  $s = substr( $date, 0, 4 );            #yyyy
  $s = $s . '-' . substr( $date, 4, 2 ); #-mm
  $s = $s . '-' . substr( $date, 6, 2 ); #-dd
  $s = $s . ' ' . substr( $date, 8, 8 ); # hh:mm:mm

  return( $s );

}


if (! defined $stdout) {our $stdout = \*STDOUT};


print $stdout "-- Pwntter establishing database connection...\n";

# Ideally, we should connect to the DB and prepare the queries here. But, as TTYtter runs in two (more?) separate threads, each with its variables, we'll have to resort to another solution.

# But, hey, checking if the DB is up at this point is fine.

our $dbh = DBI->connect_cached("DBI:mysql:database=$db;host=$host",	"$user_id", "$password",
	{'RaiseError' => 0, 'my_pid' => $$});

print $stdout "-- Database connection established.\n";


our $pwntter_tweet_stmt;
our $pwntter_user_stmt;



$handle = sub {

	my $ref = shift;


	# Data to be inserted into the tweets table goes into a dictionary structure.
	# We'll later fetch all the dict keys, build the query, and bind all the dict values.
	### TODO: We'll be doing this dict thing several times, so create a subroutine to handle that
	### TODO: Strip null or empty fields from the query. Again, let the sub handle that.
	my %fields_tweet = ();

	print $stdout "-- Pwntter starting up\n" if ($verbose);

	$fields_tweet{'id'}            = $ref->{'id'};
	$fields_tweet{'user_id'}       = $ref->{'user'}->{'id'};

	if (! defined $ref->{'user'}{'id'}) #listed tweets need this
		{ $user_id = $ref->{'from_user_id'}; }

	$fields_tweet{'reply_id'}      = $ref->{'in_reply_to_status_id'};
	$fields_tweet{'retweet_id'}    = $ref->{'retweeted_status'}->{'id'};

	### TODO: strip off ANSI escape sequences (due to deshortify and/or bigbenclock)
	$fields_tweet{'text'}          = &descape(decode_entities($ref->{'text'}));

	### The source_id, or user agent ID, is fetched from the DB after inserting/replacing it into the known user agents table
	$fields_tweet{'source_id'}     = &$pwntter_useragent_id( &descape($ref->{'source'}) );

# 	print $stdout "-- Pwntter pre-geo\n" if ($verbose);
	$fields_tweet{'geo_lat'}       = $ref->{'geo'}->{'coordinates'}->[0];
	$fields_tweet{'geo_long'}      = $ref->{'geo'}->{'coordinates'}->[1];
# 	print $stdout "-- Pwntter post-geo\n" if ($verbose);
	if (defined ($ref->{'created_at'} ) )
		{ $fields_tweet{'created_at'}    = date_format(ParseDate($ref->{'created_at'})); }
	$fields_tweet{'favorited'}     = ( $ref->{'favorited'} eq "true");

	### TODO: cache known place_ids in another table
	$fields_tweet{'place_id'}      = $ref->{'place'}->{'id'};

	$fields_tweet{'possibly_sensitive'} = ( $ref->{'possibly_sensitive'} eq "true");
	$fields_tweet{'retweet_count'} = $ref->{'retweet_count'};
	$fields_tweet{'retweeted'}     = ( $ref->{'retweeted'} eq "true");	# By me
	$fields_tweet{'truncated'}     = ( $ref->{'truncated'} eq "true");

	### Not needed here, used for backwards compatibility with pwntter scripts
	$fields_tweet{'screen_name'}   = &descape($ref->{'user'}->{'screen_name'});

# 	print $stdout "-- Pwntter tweet data structs ready\n" if ($verbose);

# 	print $ref->{'created_at'} . "\n";
# 	print ParseDate($ref->{'created_at'}) . "\n";
# 	print date_format(ParseDate($ref->{'created_at'})) . "\n";


# 	print $stdout Dumper( [keys %fields_tweet] );
# 	print $stdout Dumper( [values %fields_tweet] );
#
# 	if ($created_at ne '') {$created_at = date_format($created_at);}
# 	if ($user_created_at ne ''){ $user_created_at  = date_format($user_created_at);}


	# Now, for the user data dict structure.
	my %fields_user = ();

	$fields_user{'id'}                                 = $ref->{'user'}->{'id'};
	$fields_user{'screen_name'}                        = &descape( $ref->{'user'}->{'screen_name'} );	# Not needed, but for backwards compatibility with pwntter scripts

	$fields_user{'contributors_enabled'}               = ( $ref->{'user'}->{'contributors_enabled'} eq "true");
	if (defined ($ref->{'user'}->{'created_at'} ) )
		{$fields_user{'created_at'}                = date_format( ParseDate( $ref->{'user'}->{'created_at'} )); } 	# datetime nullable
	$fields_user{'default_profile'}                    = ( $ref->{'user'}->{'default_profile'} eq "true");
	$fields_user{'default_profile_image'}              = ( $ref->{'user'}->{'default_profile_image'} eq "true");
	$fields_user{'description'}                        = &descape(decode_entities( $ref->{'user'}->{'description'} ));
	$fields_user{'favorites_count'}                    = $ref->{'user'}->{'favorites_count'};
	$fields_user{'follow_request_sent'}                = ( $ref->{'user'}->{'follow_request_sent'} eq "true"); # nullable
	$fields_user{'following'}                          = ( $ref->{'user'}->{'following'} eq "true"); #nullable
	$fields_user{'followers_count'}                    = $ref->{'user'}->{'followers_count'};
	$fields_user{'friends_count'}                      = $ref->{'user'}->{'friends_count'};
	$fields_user{'geo_enabled'}                        = ( $ref->{'user'}->{'geo_enabled'} eq "true");
	$fields_user{'is_translator'}                      = ( $ref->{'user'}->{'is_translator'} eq "true");
	$fields_user{'lang'}                               = &descape( $ref->{'user'}->{'lang'} );
	$fields_user{'listed_count'}                       = $ref->{'user'}->{'listed_count'};
	$fields_user{'location'}                           = &descape(decode_entities( $ref->{'user'}->{'location'} ));
	$fields_user{'name'}                               = &descape(decode_entities( $ref->{'user'}->{'name'} )) ;
	$fields_user{'notifications'}                      = ( $ref->{'user'}->{'notifications'} eq "true"); #nullable
	$fields_user{'profile_background_color'}           = &descape( $ref->{'user'}->{'profile_background_color'} );
	$fields_user{'profile_background_image_url'}       = &descape( $ref->{'user'}->{'profile_background_image_url'} );
	$fields_user{'profile_background_image_url_https'} = &descape( $ref->{'user'}->{'profile_background_image_url_https'} );
	$fields_user{'profile_background_tile'}            = ( $ref->{'user'}->{'profile_background_tile'} eq "true");
	$fields_user{'profile_banner_url'}                 = &descape( $ref->{'user'}->{'profile_banner_url'} );
	$fields_user{'profile_image_url'}                  = &descape( $ref->{'user'}->{'profile_image_url'} );
	$fields_user{'profile_image_url_https'}            = &descape( $ref->{'user'}->{'profile_image_url_https'} );
	$fields_user{'profile_link_color'}                 = &descape( $ref->{'user'}->{'profile_link_color'} );
	$fields_user{'profile_sidebar_border_color'}       = &descape( $ref->{'user'}->{'profile_sidebar_border_color'} );
	$fields_user{'profile_sidebar_fill_color'}         = &descape( $ref->{'user'}->{'profile_sidebar_fill_color'} );
	$fields_user{'profile_text_color'}                 = &descape( $ref->{'user'}->{'profile_text_color'} );
	$fields_user{'profile_use_background_image'}       = ( $ref->{'user'}->{'profile_use_background_image'} eq "true");
	$fields_user{'protected'}                          = ( $ref->{'user'}->{'protected'} eq "true");
	$fields_user{'show_all_inline_media'}              = ( $ref->{'user'}->{'show_all_inline_media'} eq "true");
	$fields_user{'status'}                             = &descape(decode_entities($ref->{'user'}->{'status'} ));
	$fields_user{'statuses_count'}                     = $ref->{'user'}->{'statuses_count'};
	$fields_user{'time_zone'}                          = &descape( $ref->{'user'}->{'time_zone'} );
	$fields_user{'url'}                                = &descape( $ref->{'user'}->{'url'} );
	$fields_user{'utc_offset'}                         = $ref->{'user'}->{'utc_offset'};
	$fields_user{'verified'}                           = ( $ref->{'user'}->{'verified'} eq "true");

# 	print $stdout Dumper($ref);
# 	print (Dumper(%fields_user));

	print $stdout "-- Pwntter tweet and user data structs ready\n" if ($verbose);


	&$pwntter_perform_query( \%fields_user , "users");
	print $stdout "-- Pwntter logged user: $ref->{'user'}->{'screen_name'}\n" if ($verbose);

	&$pwntter_perform_query( \%fields_tweet , "tweets");
	print $stdout "-- Pwntter logged new tweet: $ref->{'id'}\n" if ($verbose);


	# Media
	while (my ($i, $val) = each $ref->{'entities'}->{'urls'}) {
# 		print "$i => " . Dumper($val);
		my %fields_media = ();
		$fields_media->{'display_url'}      = $val->{'display_url'};
		$fields_media->{'expanded_url'}     = $val->{'expanded_url'};
		$fields_media->{'media_url'}        = $val->{'media_url'};
		$fields_media->{'media_url_https'}  = $val->{'media_url_https'};
		$fields_media->{'media_url_md5'}    = md5_base64 $val->{'expanded_url'};
		if ($val->{'source_status_id'})
		{
			$fields_media->{'source_status_id'} = $val->{'source_status_id'};
		}
		else
		{
			$fields_media->{'source_status_id'} = $ref->{'id'};
		}

# 		print Dumper($fields_media);

		&$pwntter_perform_query( $fields_media , "media", "media_url_md5");

		my %fields_media_tweets = ();
		$fields_media_tweets->{'media_url_md5'}      = md5_base64 $val->{'expanded_url'};
		$fields_media_tweets->{'tweet_id'}     = $ref->{'id'};

		&$pwntter_perform_query( $fields_media_tweets , "media_tweets", "media_url_md5");

		print $stdout "-- Pwntter logged new media: Tweet $ref->{'id'} refs media $val->{'expanded_url'}\n" if ($verbose);
	}



	# URLs
	while (my ($i, $val) = each $ref->{'entities'}->{'urls'}) {
# 		print "$i => " . Dumper($val);
		my %fields_url = ();
		$fields_url->{'display_url'}  = $val->{'display_url'};
		$fields_url->{'expanded_url'} = $val->{'expanded_url'};
		$fields_url->{'url'}          = $val->{'url'};
		$fields_url->{'url_md5'}      = md5_base64 $val->{'expanded_url'};

# 		print Dumper($fields_url);

		&$pwntter_perform_query( $fields_url , "urls", "url_md5");

		my %fields_url_tweets = ();
		$fields_url_tweets->{'url_md5'}      = md5_base64 $val->{'expanded_url'};
		$fields_url_tweets->{'tweet_id'}     = $ref->{'id'};

		&$pwntter_perform_query( $fields_url_tweets , "url_tweets", "url_md5");

		print $stdout "-- Pwntter logged new url: Tweet $ref->{'id'} refs URL $val->{'url'}\n" if ($verbose);
	}

	# Mentions
	while (my ($i, $val) = each $ref->{'entities'}->{'user_mentions'}) {
# 		print "$i => " . Dumper($val);
		my %fields_mention = ();
		$fields_mention->{'tweet_id'}  = $ref->{'id'};
		$fields_mention->{'user_id'}   = $val->{'id'};

# 		print Dumper($fields_mention);

		&$pwntter_perform_query( $fields_mention , "mentions", "tweet_id" , , 1);

		# TODO: Also store available data about unknown users
		print $stdout "-- Pwntter logged new mention: Tweet $ref->{'id'} refs user $val->{'id'}\n" if ($verbose);
	}




	&defaulthandle($tweet);

	return 1;
};



#
# $dmhandle = sub {
#
# 	my $ref = shift;
# 	our $dbh;
#
# 	if (true)
# 	{
# # 		$dbh = DBI->connect_cached("DBI:mysql:database=$db;host=$host", "$user_id", "$password",
# 		$dbh = DBI->connect("DBI:mysql:database=$db;host=$host", "$user_id", "$password",
# 			{'RaiseError' => 0, 'my_pid' => $$})
# 			or &$exception(2,"*** Could not connect to DB: " . $DBI::errstr . "\n");;
# 	}
# 	our $pwntter_dm_stmt;
# 	our $pwntter_dm_sender_stmt;
#
# 	#Direct Message data
# 	my $id = $ref->{'id_str'};
# 	my $sender_id = &descape($ref->{'sender_id'});
# 	my $text = &descape(decode_entities($ref->{'text'}));
# 	my $recipient_id = &descape($ref->{'recipient_id'});
# 	my $created_at = ParseDate($ref->{'created_at'});
# 	my $sender_screen_name = &descape($ref->{'sender_screen_name'});
# 	my $recipient_screen_name = &descape($ref->{'recipient_screen_name'});
#
#
# 	#sender data
# 	my $user_id = $ref->{'sender'}->{'id'};
# 	my $name = &descape($ref->{'sender'}->{'name'});
# 	my $screen_name = &descape($ref->{'sender'}->{'screen_name'});
# 	my $description = &descape($ref->{'sender'}->{'description'});
# 	my $profile_image_url = &descape($ref->{'sender'}->{'profile_image_url'});
# 	my $location = &descape($ref->{'sender'}->{'location'});
# 	my $url = &descape($ref->{'sender'}->{'url'});
# 	my $protected = ($ref->{'sender'}->{'protected'} eq "true");
# 	my $followers_count = $ref->{'sender'}->{'followers_count'};
# 	my $friends_count = $ref->{'sender'}->{'friends_count'};
# 	my $user_created_at = ParseDate($ref->{'sender'}->{'created_at'});
# 	my $favourites_count = $ref->{'sender'}->{'favourites_count'};
# 	my $utc_offset = $ref->{'sender'}->{'utc_offset'};
# 	my $time_zone = $ref->{'sender'}->{'time_zone'};
# 	my $statuses_count	= $ref->{'sender'}->{'statuses_count'};
# 	my $following = ($ref->{'user'}->{'following'} eq "true");
# 	my $verified = ($ref->{'user'}->{'verified'} eq "true");
#
# 	#format dates to mysql datetime format YYYY-MM-DD HH:MM:SS
# 	$created_at = date_format($created_at);
# 	$user_created_at = date_format($user_created_at);
#
#
# # 	if (not $pwntter_tweet_stmt)
# 	if (true)	# Damned TTYtter multi-thread environs
# 	{
# 		print $stdout "-- Pwntter preparing statement (for DMs)\n" if ($verbose);
#
# 		my $pwntter_dm_sql = "replace into `direct_messages` " .
# 			"SET `id` = ?, " .
# 			" `sender_id` = ?, " .
# 			" `text` = ?, " .
# 			" `recipient_id` = ?, " .
# 			" `created_at` = ?, " .
# 			" `sender_screen_name` = ?, " .
# 			" `recipient_screen_name` =?";
# 		$pwntter_dm_stmt = $dbh->prepare_cached($pwntter_dm_sql,{'TTYtter enviro' => $is_background})
# 			or 	&$exception(2,"*** Pwntter could not prepare database statement (for DMs) due to " . $DBI::errstr . ".\n");
# 	}
#
# 	$pwntter_dm_stmt->execute(
# 		$id,
# 		$sender_id,
# 		$text,
# 		$recipient_id,
# 		$created_at,
# 		$sender_screen_name,
# 		$recipient_screen_name
# 		) or 	&$exception(2,"*** Pwntter could not insert data into DB (for DMs) due to " . $DBI::errstr . ".\n");;
#
#
# # 	if (not $pwntter_tweet_stmt)
# 	if (true)	# Damned TTYtter multi-thread environs
# 	{
# 		print $stdout "-- Pwntter preparing statement (for DM senders)\n" if ($verbose);
#
# 		my $pwntter_dm_sender_sql = "replace into `users` " .
# 			"SET `id` = ?, " .
# 			" `name` = ?, " .
# 			" `screen_name` = ?, " .
# 			" `description` = ?, " .
# 			" `location` = ?, " .
# 			" `profile_image_url` = ?, " .
# 			" `url` = ?, " .
# 			" `protected` = ?, " .
# 			" `followers_count` = ?, " .
# 			" `friends_count` = ?, " .
# 			" `created_at` = ?, " .
# 			" `favourites_count` = ?, " .
# 			" `utc_offset` = ?, " .
# 			" `time_zone` = ?, " .
# 			" `statuses_count` = ?, " .
# 			" `following` = ?, " .
# 			" `verified` = ?";
#
# 		our $pwntter_dm_sender_stmt = $dbh->prepare_cached($pwntter_dm_sender_sql,{'TTYtter enviro' => $is_background})
# 			or 	&$exception(2,"*** Pwntter could not prepare database statement (for DM senders) due to " . $DBI::errstr . ".\n");
# 	}
#
#
# 	if ( $utc_offset == "") { $utc_offset = 0; }
#
# 	$pwntter_dm_sender_stmt->execute(
# 		$user_id,
# 		$name,
# 		$screen_name,
# 		$description,
# 		$location,
# 		$profile_image_url,
# 		$url,
# 		$protected,
# 		$friends_count,
# 		$followers_count,
# 		$created_at,
# 		$favourites_count,
# 		$utc_offset,
# 		$time_zone,
# 		$statuses_count,
# 		$following,
# 		$verified
# 		) or 	&$exception(2,"*** Pwntter could not insert data into DB (for DM senders) due to " . $DBI::errstr . ".\n");;
#
#
#
#
#
# 	return 1;
# };





our $pwntter_useragent_id = sub {

# 	return 1;

	my $source = shift;
	my $name = '';
	my $url = '';

	# TODO: regexp the URL and name

	if ($source eq "web")
	{
		$name = "web";
	}
	if ($source =~ m#^<a href="(.*?)" .*>(.*?)</a>$# )
	{
		$url = $1;
		$name = $2;
		($scheme, $auth, $path, $query, $frag) = uri_split($url);
	}

# 	print "$url -- $name -- $source \n";

	if (true)	# Damned TTYtter multi-thread environs
	{
		$dbh = DBI->connect("DBI:mysql:database=$db;host=$host", "$user_id", "$password",
			{'RaiseError' => 0, 'PrintError' => 0, 'my_pid' => $$})
			or &$exception(33,"*** Could not connect to DB: " . $DBI::errstr . "\n");
	}


	$stmt = $dbh->prepare("select id from sources where name=?");
	$rv = $stmt->execute($name);

	if(@row = $stmt->fetchrow_array()) {
		return $row[0];
	}

	# If there is no data in the DB, perform an insert.
	$stmt = $dbh->prepare("insert into sources(name,url,icon) values(?,?,?)");

	# TODO: check if the favicon really exists.
	$stmt->execute($name,$url,"$scheme://$auth/favicon.ico")
		or &$exception(33,"*** Could not connect to DB: " . $DBI::errstr . "\n");;


	print $stdout("---- Pwntter adding a new twitter user agent ($url -- $name)\n");
# 	 if ($verbose);

	return $dbh->last_insert_id(undef, undef, 'sources', undef);
};




# Generic thingie for inserting a record into a DB table.
our $pwntter_perform_query = sub {

# 	return 1;

# 	my $fields = $_[0];	# Why not shift this dict ref param? Mi perl-fu is weak :-(
# 	my $table = $_[1];

	my $fields = shift;
	my $table = shift;
	my $pkey = shift;
	my $retry_connect = shift;
	my $ignore_errors = shift;

	if (not defined $pkey) { $pkey = 'id'; }
	if (not defined $retry_connect) { $retry_connect = true; }


	my @field_keys = (keys $fields);
	my @field_values = (values $fields);

# 	print Dumper($fields);
# 	print Dumper($fields->{'id'});
# 	print Dumper(%fields);
# 	print Dumper(@field_keys);
# 	print Dumper(@field_values);
# 	print Dumper($table);
# 	print Dumper($pkey);
# 	print Dumper($retry_connect);

	my $i = 0;
	my $j = 0;
	my $sql_update_fields = "";
	my $sql_insert_fields = "";
	my $sql_insert_values = "";
	my @sql_bound_values = ();
	for my $field ( @field_keys )
	{
		my $fieldname = $field_keys[$i];
		my $fieldvalue = $field_values[$i];

# 		print $i . ": " . $fieldname . " = " . $fieldvalue . "\n";

		if (not $fieldvalue eq undef and not $fieldvalue eq '' and not $fieldvalue eq 0)	# Skip null / undef values
		{
			my $comma = "";
			if ($j > 0) { $comma = ","; }

			$sql_update_fields .= "$comma`$fieldname`=?";
			$sql_insert_fields .= "$comma`$fieldname`";
			$sql_insert_values .= "$comma?";

			$sql_bound_values[$j] = $fieldvalue;

			$j++;
		}
		$i++;
	}

	my $sql_update = "update $table set $sql_update_fields where $pkey = ? ";
	my $sql_insert = "insert into $table ($sql_insert_fields) values ($sql_insert_values)";


# 	print $sql_update . "\n";
# 	print $sql_insert . "\n";
# 	print Dumper(@sql_bound_values);


	# TODO: implement persistent or cached connections and statements.
	# TODO: implement fallback for failed persistent statement executions

# 	our $dbh;
	my $dbh;
# 	if (not defined $dbh )
	if (true)	# Damned TTYtter multi-thread environs
	{
		$dbh = DBI->connect("DBI:mysql:database=$db;host=$host", "$user_id", "$password",
			{'RaiseError' => 0, 'PrintError' => 0, 'my_pid' => $$})
			or &$exception(33,"*** Could not connect to DB: " . $DBI::errstr . "\n");;
	}

	my $stmt;
	my $ok;
	my $last;

	$stmt = $dbh->prepare($sql_insert);

	if ($stmt)
	{
		print "-- Pwntter Inserting data in $table\n" if ($superverbose);
		$ok = $stmt->execute(@sql_bound_values);
		if ($ok) { $last = $dbh->last_insert_id(undef, undef, $table, undef); }
# 		print Dumper($ok);
	}

	if (not $stmt or not $ok)	# Insert has failed somehow, try updating
	{
		print "-- Pwntter updating data in $table\n" if ($superverbose);

		$stmt = $dbh->prepare($sql_update);
		$sql_bound_values[$j] = $fields->{$pkey};

# 		print Dumper(@sql_bound_values);

		$ok = $stmt->execute(@sql_bound_values);
# 		if ($@)
		if (not $ok)
		{
			if ($ignore_errors)
			{
				&$exception(33,"*** $ignore_errors Pwntter DB error: " . $DBI::errstr . "\n");
			}
			return 0;
		}
		else
		{
			$last = $fields->{$pkey};
		}
	}

	# TODO: return last inserted ID / updated ID.
	return $last;
};








#
#
#  $tweet_data = {
#  	'retweeted' => 'false',
#  	'source' => '\\u003ca href="http:\\/\\/www.britishideas.com" rel="nofollow"\\u003eOSM Changeset Bot\\u003c\\/a\\u003e',
#  	'favorited' => 'false',
#  	'coordinates' => undef,
#  	'place' => undef,
#  	'retweet_count' => 0,
#  	'entities' => {
#  		'user_mentions' => [{'name'=>'Twitter API', 'indices'=>[4,15], 'screen_name'=>'twitterapi', 'id'=>6253282, 'id_str'=>'6253282'}],
#  		'hashtags' => [{'indices'=>[32,36],'text'=>'lol'}],
#  		'urls' => [
#  			{
#  			'display_url' => 'osm.org\\/browse\\/changes\\u2026',
#  			'expanded_url' => 'http:\\/\\/www.osm.org\\/browse\\/changeset\\/14462456',
#  			'url' => 'http:\\/\\/t.co\\/PKaWsltH',
#  			'indices' => [
#  				68,
#  				88
#  				]
#  			},
#  			{
#  			'display_url' => 'osm.org\\/browse\\/changes\\u20267777',
#  			'expanded_url' => 'http:\\/\\/www.osm.org\\/browse\\/changeset\\/144624567777',
#  			'url' => 'http:\\/\\/t.co\\/PKaWsltH7777',
#  			'indices' => [
#  				68,
#  				88
#  				]
#  			}
#  			]
#  		},
#  	'truncated' => 'false',
#  	'created_at' => 'Sun Dec 30 12:50:02 +0000 2012',
#  	'in_reply_to_status_id_str' => undef,
#  	'contributors' => undef,
#  	'text' => 'New Footpaths to the East of Watton by geoff1257 (using Potlatch 2) http://www.osm.org/browse/changeset/14462456',
#  	'user' => {
#  		'friends_count' => 0,
#  		'follow_request_sent' => undef,
#  		'profile_sidebar_fill_color' => 'A0C5C7',
#  		'profile_image_url' => 'http:\\/\\/a0.twimg.com\\/profile_images\\/373331137\\/osm_logo_normal.png',
#  		'profile_background_image_url_https' => 'https:\\/\\/si0.twimg.com\\/images\\/themes\\/theme1\\/bg.png',
#  		'entities' => {
#  			'description' => {
#  				'urls' => []
#  				}
#  			},
#  		'profile_background_color' => '1B607D',
#  		'notifications' => undef,
#  		'url' => undef,
#  		'id' => 6749372211111111,
#  		'following' => undef,
#  		'is_translator' => 'false',
#  		'screen_name' => 'osmeastriding',
#  		'lang' => 'en',
#  		'location' => '',
#  		'followers_count' => 45,
#  		'statuses_count' => 9587,
#  		'name' => 'OSM East Riding',
#  		'description' => 'OSM data CCBYSA',
#  		'favourites_count' => 0,
#  		'profile_background_tile' => 'false',
#  		'listed_count' => 3,
#  		'contributors_enabled' => 'false',
#  		'profile_link_color' => 'AB415D',
#  		'profile_image_url_https' => 'https:\\/\\/si0.twimg.com\\/profile_images\\/373331137\\/osm_logo_normal.png',
#  		'profile_sidebar_border_color' => '86A4A6',
#  		'created_at' => 'Fri Aug 21 02:09:11 +0000 2009',
#  		'utc_offset' => -28800,
#  		'verified' => 'false',
#  		'profile_background_image_url' => 'http:\\/\\/a0.twimg.com\\/images\\/themes\\/theme1\\/bg.png',
#  		'default_profile' => 'false',
#  		'protected' => 'false',
#  		'id_str' => '67493722',
#  		'profile_text_color' => '000000',
#  		'default_profile_image' => 'false',
#  		'time_zone' => 'Pacific Time (US & Canada)',
#  		'geo_enabled' => 'false',
#  		'profile_use_background_image' => 'false'
#  		},
#  	'in_reply_to_user_id' => undef,
#  	'tag' => {
#  		'payload' => 'q=bofhers%20OR%20openstreetmap%20OR%20emtmadrid',
#  		'type' => 'search'
#  		},
#  	'metadata' => {
#  		'result_type' => 'recent',
#  		'iso_language_code' => 'en'
#  		},
#  	'id' => '285367139949477888',
#  	'in_reply_to_status_id' => undef,
#  	'geo' => {
#  		'coordinates' => [
#  			'undef',
#  			'undef'
#  			]
#  		},
#  	'possibly_sensitive' => 'false',
#  	'in_reply_to_user_id_str' => undef,
#  	'id_str' => '285367139949477888',
#  	'menu_select' => 'a0',
#  	'class' => 'search',
#  	'in_reply_to_screen_name' => undef
#  };
#
# #
# #
# #
# #
# #
# my $utf8_decode = sub { utf8::decode(shift); };
#
# sub descape
# {
#   my $text = shift;
#   return $text;
# }
#
# $exception = sub {
# 	print "*** Error!!!\n";
# 	print Dumper(shift) ;
# 	print Dumper(shift) ;
# 	print "***\n";
# 	};
#
# &$handle($tweet_data);


#
#
# sub descape {
# 	my $x = shift;
# 	my $mode = shift;
#
# 	$x =~ s#\\/#/#g;
#
# 	# try to do something sensible with unicode
# 	if ($mode) { # this probably needs to be revised
# 		$x =~ s/\\u([0-9a-fA-F]{4})/"&#" . hex($1) . ";"/eg;
# 	} else {
# 		# intermediate form if HTML entities get in
# 		$x =~ s/\&\#([0-9]+);/'\u' . sprintf("%04x", $1)/eg;
#
# 		$x =~ s/\\u202[89]/\\n/g;
#
# 		# canonicalize Unicode whitespace
# 		1 while ($x =~ s/\\u(00[aA]0)/ /g);
# 		1 while ($x =~ s/\\u(200[0-9aA])/ /g);
# 		1 while ($x =~ s/\\u(20[25][fF])/ /g);
# 		if ($seven) {
# 			# known UTF-8 entities (char for char only)
# 			$x =~ s/\\u201[89]/\'/g;
# 			$x =~ s/\\u201[cCdD]/\"/g;
#
# 			# 7-bit entities (32-126) also ok
# 	$x =~ s/\\u00([2-7][0-9a-fA-F])/chr(((hex($1)==127)?46:hex($1)))/eg;
#
# 			# dot out the rest
# 			$x =~ s/\\u([0-9a-fA-F]{4})/./g;
# 			$x =~ s/[\x80-\xff]/./g;
# 		} else {
# 			# try to promote to UTF-8
# # 			&$utf8_decode($x);
#
# 			# Twitter uses UTF-16 for high code points, which
# 			# Perl's UTF-8 support does not like as surrogates.
# 			# try to decode these here; they are always back-to-
# 			# back surrogates of the form \uDxxx\uDxxx
# 			$x =~
# s/\\u([dD][890abAB][0-9a-fA-F]{2})\\u([dD][cdefCDEF][0-9a-fA-F]{2})/&deutf16($1,$2)/eg;
#
# 			# decode the rest
# 			$x =~ s/\\u([0-9a-fA-F]{4})/chr(hex($1))/eg;
# # 			$x = &uforcemulti($x);
# 		}
# 		$x =~ s/\&quot;/"/g;
# 		$x =~ s/\&apos;/'/g;
# 		$x =~ s/\&lt;/\</g;
# 		$x =~ s/\&gt;/\>/g;
# 		$x =~ s/\&amp;/\&/g;
# 	}
# 	if ($newline) {
# 		$x =~ s/\\n/\n/sg;
# 		$x =~ s/\\r//sg;
# 	}
# 	return $x;
# };
#










