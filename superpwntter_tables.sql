

-- See https://dev.twitter.com/docs/platform-objects/tweets


DROP TABLE IF EXISTS tweets;

CREATE TABLE tweets (

	 id		bigint unsigned not null primary key	-- or "serial" in PGSQL
	,user_id	bigint unsigned not null	-- references users, must find
	,reply_id	bigint unsigned	-- references tweets, in_reply_to_status_id
	,retweet_id	bigint unsigned	-- retweeted_status, references tweets
	,`text`		text not null
	,source_id	int unsigned not null	-- references sources, must find adequate ID

	-- ,annotations	text	-- unused, reserved for future reference

	,geo_lat	float	-- May use tweet->geo (old) or tweet->coordinates
	,geo_long	float
	,created_at	datetime not null
	,favorited	boolean	-- favorited by the reading user
	,place_id	bigint unsigned not null	-- tweet->place->id (hex)
	,possibly_sensitive	bool
	-- ,scopes	text	-- value-key pairs, used by promoted tweets
	,retweet_count	int not null default 0	-- times this tweet has been retweeted
	,retweeted	bool not null default false -- By me
	,truncated	bool not null default false
	-- ,withheld_copyright	bool not null default false
	-- ,withheld_in_countries	text
	-- ,withheld_scope	text	-- either "status" or "user"

	,screen_name	tinytext	-- Not really needed (it's the screen_name in the users table) but provides backwards compatibility woth pwntter scripts.

) DEFAULT CHARSET=utf8;


-- many-to-many relationships to tweets:

-- contributors

-- Tweet entities: tables for-- URLs
-- mentions
-- hashtags




DROP TABLE IF EXISTS users;

CREATE TABLE users (

	 id		bigint unsigned not null primary key	-- or "serial" in PGSQL
	,screen_name	tinytext

	,contributors_enabled	bool not null default false -- Others can tweet on behalf
	,created_at	datetime not null
	,default_profile	bool not null default false	-- Hasn't configured anything
	,default_profile_image	bool not null default false	-- Egg avatar
	,description	text
	,favourites_count	int not null default 0	-- tweets this user has fav'd
	,follow_request_sent	bool -- Have I req'd following this protected acc't?
	,following	bool -- deprecated
	,followers_count	int not null default 0
	,friends_count	int not null default 0	-- following
	,geo_enabled	bool not null default false
	,is_translator	bool not null default false
	,lang		tinytext not null -- bcp47 code
	,listed_count	int not null default 0	-- # of lists this user is in
	,location	text
	,name 		text
	,notifications	bool	-- deprecated
	,profile_background_color	tinytext not null
	,profile_background_image_url	text
	,profile_background_image_url_https	text
	,profile_background_tile	bool not null default false
	,profile_banner_url	text
	,profile_image_url	text
	,profile_image_url_https	text
	,profile_link_color	tinytext not null
	,profile_sidebar_border_color	tinytext not null
	,profile_sidebar_fill_color	tinytext not null
	,profile_text_color		tinytext not null
	,profile_use_background_image	bool not null default false
	,protected	bool not null default false
	,show_all_inline_media	bool not null default false
	,status		tinytext
	,statuses_count	int
	,time_zone	tinytext
	,url	text
	,utc_offset	int	-- in seconds
	,verified	bool not null default false
	-- ,withheld_in_countries	text
	-- ,withheld_scope	text
) DEFAULT CHARSET=utf8 ;







DROP TABLE IF EXISTS hashtags;

CREATE TABLE hashtags (

	 id	bigint not null primary key auto_increment	-- or "serial" in PGSQL
	,hashtag	tinytext not null
) DEFAULT CHARSET=utf8 ;





DROP TABLE IF EXISTS media;

CREATE TABLE media (

--	 id	bigint not null
-- 	,type	tinytext	-- 'photo'
	 display_url	text not null
	,media_url	text not null
	,media_url_md5	char(32) unique primary key not null
	,media_url_https	text not null
	,expanded_url	text not null
	,source_status_id	bigint

) DEFAULT CHARSET=utf8 ;



CREATE TABLE media_tweets (

	 media_url_md5	char(32) key not null
	,tweet_id	bigint unsigned not null

-- 	,primary key (url_md5, tweet_id)
	,key (media_url_md5, tweet_id)
	,unique (media_url_md5, tweet_id)
) DEFAULT CHARSET=utf8 ;






DROP TABLE IF EXISTS urls;

CREATE TABLE urls (

--	 id	bigint not null primary key auto_increment
	 url_md5	char(32) unique primary key not null
	,url	varchar(256) not null -- FIXME: This field should be unique.
	,display_url	text not null
	,expanded_url	text not null

	,index (url_md5)
) DEFAULT CHARSET=utf8 ;

DROP TABLE IF EXISTS url_tweets;

CREATE TABLE url_tweets (

	 url_md5	char(32) key not null
	,tweet_id	bigint unsigned not null

-- 	,primary key (url_md5, tweet_id)
	,key (url_md5, tweet_id)
	,unique (url_md5, tweet_id)
) DEFAULT CHARSET=utf8 ;




DROP TABLE IF EXISTS mentions;

CREATE TABLE mentions (

	 tweet_id	bigint not null
	,user_id	bigint not null

	,primary key(tweet_id, user_id)
	,unique(tweet_id, user_id)
	-- REFERENCES bla bla bla
) DEFAULT CHARSET=utf8 ;






DROP TABLE IF EXISTS sources;

CREATE TABLE sources (

	 id	bigint not null primary key auto_increment
	,name	varchar(100) not null unique
	,url	varchar(100) not null
	,icon	tinytext	-- Defaults to url /favicon.ico

	,index (name)
	,index (url)
) DEFAULT CHARSET=utf8 ;

-- The "web" client doesn't advertise a url as do every other, so let's put it in here:
insert into sources(name,url,icon) values ('web','http://www.twitter.com','http://www.twitter.com/favicon.ico');





DROP TABLE IF EXISTS places;

CREATE TABLE places (

	 id	bigint not null primary key
	,name	varchar(200) not null
	,full_name	tinytext not null
	,country	tinytext not null
	,country_code	tinytext not null
	,bbox_sw	float not null	-- south west
	,bbox_nw	float not null	-- north west
	,bbox_ne	float not null	-- north east
	,bbox_se	float not null	-- south east
	,place_type	tinytext	-- e.g. city
	,url	varchar(200) not null	-- Visit for more metadata

	,attr_street_address	tinytext
	,attr_locality	tinytext
	,attr_region	tinytext
	,attr_iso3	tinytext
	,attr_postal_code	tinytext
	,attr_phone	tinytext
	,attr_twitter	tinytext
	,attr_url	tinytext
-- 	,attr_app_id	tinytext	-- comma-separated list, investigate further

	,index (name)
	,index (url)
) DEFAULT CHARSET=utf8 ;











DROP TABLE IF EXISTS `direct_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `direct_messages` (
  `id` bigint(20) unsigned NOT NULL,
  `sender_id` bigint(20) NOT NULL,
  `text` text NOT NULL,
  `recipient_id` bigint(20) unsigned NOT NULL,
  `created_at` datetime NOT NULL,
  `sender_screen_name` varchar(20) NOT NULL,
  `recipient_screen_name` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sender_id_index` (`sender_id`),
  KEY `recipient_id_index` (`recipient_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COMMENT='Direct Messages';
/*!40101 SET character_set_client = @saved_cs_client */;


















