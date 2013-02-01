--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: superpwntter; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE superpwntter WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'es_ES.UTF-8' LC_CTYPE = 'es_ES.UTF-8';


\connect superpwntter

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: superpwntter; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON DATABASE superpwntter IS 'Base de datos que almacena la información recogida de Twitter por la extension superpwntter.pl';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: direct_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE direct_messages (
    id bigint NOT NULL,
    sender_id bigint NOT NULL,
    text text NOT NULL,
    recipient_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    sender_screen_name character varying(20) NOT NULL,
    recipient_screen_name character varying(20) NOT NULL
);


--
-- Name: hashtags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE hashtags (
    id serial NOT NULL,
    hashtag text NOT NULL
);


--
-- Name: media; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE media (
    display_url text NOT NULL,
    media_url text NOT NULL,
    media_url_md5 character(32) NOT NULL,
    media_url_https text NOT NULL,
    expanded_url text NOT NULL,
    source_status_id bigint
);


--
-- Name: media_tweets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE media_tweets (
    media_url_md5 character(32) NOT NULL,
    tweet_id bigint NOT NULL
);


--
-- Name: mentions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mentions (
    tweet_id bigint NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: places; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE places (
    id bigint NOT NULL,
    name character varying(200) NOT NULL,
    full_name text NOT NULL,
    country text NOT NULL,
    country_code text NOT NULL,
    bbox_sw double precision NOT NULL,
    bbox_nw double precision NOT NULL,
    bbox_ne double precision NOT NULL,
    bbox_se double precision NOT NULL,
    place_type text,
    url character varying(200) NOT NULL,
    attr_street_address text,
    attr_locality text,
    attr_region text,
    attr_iso3 text,
    attr_postal_code text,
    attr_phone text,
    attr_twitter text,
    attr_url text
);


--
-- Name: sources; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sources (
    id serial,
    name character varying(100) NOT NULL,
    url character varying(100) NOT NULL,
    icon text
);


--
-- Name: tweets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tweets (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    reply_id bigint,
    retweet_id bigint,
    text text NOT NULL,
    source_id integer NOT NULL,
    geo_lat double precision,
    geo_long double precision,
    created_at timestamp without time zone NOT NULL,
    favorited boolean,
    place_id bigint,
    possibly_sensitive boolean,
    retweet_count integer DEFAULT 0 NOT NULL,
    retweeted boolean DEFAULT false NOT NULL,
    truncated boolean DEFAULT false NOT NULL,
    screen_name text
);


--
-- Name: url_tweets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE url_tweets (
    url_md5 character(32) NOT NULL,
    tweet_id bigint NOT NULL
);


--
-- Name: urls; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE urls (
    url_md5 character(32) NOT NULL,
    url character varying(256) NOT NULL,
    display_url text NOT NULL,
    expanded_url text NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    screen_name text,
    contributors_enabled boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    default_profile boolean DEFAULT false NOT NULL,
    default_profile_image boolean DEFAULT false NOT NULL,
    description text,
    favourites_count integer DEFAULT 0 NOT NULL,
    follow_request_sent boolean,
    following boolean,
    followers_count integer DEFAULT 0 NOT NULL,
    friends_count integer DEFAULT 0 NOT NULL,
    geo_enabled boolean DEFAULT false NOT NULL,
    is_translator boolean DEFAULT false NOT NULL,
    lang text NOT NULL,
    listed_count integer DEFAULT 0 NOT NULL,
    location text,
    name text,
    notifications boolean,
    profile_background_color text NOT NULL,
    profile_background_image_url text,
    profile_background_image_url_https text,
    profile_background_tile boolean DEFAULT false NOT NULL,
    profile_banner_url text,
    profile_image_url text,
    profile_image_url_https text,
    profile_link_color text NOT NULL,
    profile_sidebar_border_color text NOT NULL,
    profile_sidebar_fill_color text NOT NULL,
    profile_text_color text NOT NULL,
    profile_use_background_image boolean DEFAULT false NOT NULL,
    protected boolean DEFAULT false NOT NULL,
    show_all_inline_media boolean DEFAULT false NOT NULL,
    status text,
    statuses_count integer,
    time_zone text,
    url text,
    utc_offset integer,
    verified boolean DEFAULT false NOT NULL
);

--
-- Name: direct_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY direct_messages
    ADD CONSTRAINT direct_messages_pkey PRIMARY KEY (id);


--
-- Name: hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY hashtags
    ADD CONSTRAINT hashtags_pkey PRIMARY KEY (id);


--
-- Name: media_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY media
    ADD CONSTRAINT media_pkey PRIMARY KEY (media_url_md5);


--
-- Name: media_tweets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY media_tweets
    ADD CONSTRAINT media_tweets_pkey PRIMARY KEY (media_url_md5, tweet_id);


--
-- Name: mentions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mentions
    ADD CONSTRAINT mentions_pkey PRIMARY KEY (tweet_id, user_id);


--
-- Name: places_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY places
    ADD CONSTRAINT places_pkey PRIMARY KEY (id);


--
-- Name: sources_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sources
    ADD CONSTRAINT sources_name_key UNIQUE (name);


--
-- Name: sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: tweets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tweets
    ADD CONSTRAINT tweets_pkey PRIMARY KEY (id);


--
-- Name: url_tweets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY url_tweets
    ADD CONSTRAINT url_tweets_pkey PRIMARY KEY (url_md5, tweet_id);


--
-- Name: urls_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY urls
    ADD CONSTRAINT urls_pkey PRIMARY KEY (url_md5);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: direct_messages_recipient_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX direct_messages_recipient_id_idx ON direct_messages USING btree (recipient_id);


--
-- Name: direct_messages_sender_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX direct_messages_sender_id_idx ON direct_messages USING btree (sender_id);


--
-- Name: places_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX places_name_idx ON places USING btree (name);


--
-- Name: places_url_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX places_url_idx ON places USING btree (url);


--
-- Name: sources_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX sources_name_idx ON sources USING btree (name);


--
-- Name: sources_url_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX sources_url_idx ON sources USING btree (url);


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- The "web" client doesn't advertise a url as do every other, so let's put it in here:
insert into sources(name,url,icon) values ('web','http://www.twitter.com','http://www.twitter.com/favicon.ico');
