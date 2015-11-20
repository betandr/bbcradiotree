#!/usr/bin/env ruby
require 'twitter'
require 'sqlite3'
require 'yaml'

def handle_tweet(tweet)
	puts "#{tweet.user.screen_name} : #{} >> #{tweet.full_text}"
end

begin
	db = SQLite3::Database.new "bbcradiotree.sqlite3"
	db.execute "CREATE TABLE IF NOT EXISTS Tweets(Id INTEGER PRIMARY KEY, Name TEXT)"

	secrets = YAML::load(File.open('secrets.yaml'))

	# boot tree

	loop do
		begin
			puts "starting Twitter streaming..."

			client = Twitter::Streaming::Client.new do |config|
			    config.consumer_key        = secrets['consumer_key']
			    config.consumer_secret     = secrets['consumer_secret']
			    config.access_token        = secrets['access_token']
			    config.access_token_secret = secrets['access_token_secret']
			end

			client.user do |tweet|
				# handle tweet if it wasn't sent by bbcradiotree but was sent to bbcradiotree
	  		handle_tweet(tweet) if tweet.is_a?(Twitter::Tweet) and tweet.user.screen_name != 'bbcradiotree' and tweet.in_reply_to_screen_name == 'bbcradiotree'
			end

		rescue => e
			puts e.message
		end
	end

rescue SQLite3::Exception => e
    puts e

ensure
    db.close if db
end