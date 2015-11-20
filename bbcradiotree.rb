#!/usr/bin/env ruby
require 'rubygems'
require 'serialport'
require 'twitter'
require 'sqlite3'

RED_MASK = 1
GREEN_MASK = 2
BLUE_MASK = 4

last_updated = Time.now

def greeting
    [
        "Happy Christmas!",
        "Seasons greetings!",
        "Happy holidays!",
        "Gledileg Jol!",
        "Yuletide greetings!",
        "Glad tidings to you!",
        "Joyeux Noël!",
        "God Jul!",
        "Jolly holidays!",
        "Fab holidays!",
        "Holiday blessings!",
        "Glad tidings!",
        "Good tidings!",
        "Yule love!",
        "Festive joy!",
        "Rockin' Christmas!",
        "Tis the season!",
        "Feliz Navidad!",
        "Ho, ho, ho!"
    ].sample
end

def reason
[
    "due to",
    "just because of",
    "for",
    "because of",
    "for the lovely",
    "all because of",
    "cos of",
    "thanks to"
].sample
end

def status
[
    "I'm now",
    "Check me out, I'm",
    "My branches are radient in",
    "See me all",
    "I'm glowing in",
    "My needles are",
    "Look at me, all"
].sample
end

def find_all_tags(text)
    found = text.scan(/#[[:alnum:]_]+/)

    safe_tags = []

    if (found.include? "\#red")
        safe_tags << "\#red"
    end

    if (found.include? "\#green")
        safe_tags << "\#green"
    end

    if (found.include? "\#blue")
        safe_tags << "\#blue"
    end

    safe_tags
end

def update_to_default
    update_lights_via_serial_port ["\#red"]
    sleep 0.5
    update_lights_via_serial_port ["\#green"]
    sleep 0.5
    update_lights_via_serial_port ["\#blue"]
    sleep 0.5
    update_lights_via_serial_port ["\#red"]
    sleep 0.5
    update_lights_via_serial_port ["\#green"]
    sleep 0.5
    update_lights_via_serial_port ["\#blue"]
    sleep 0.5
    update_lights_via_serial_port []
    sleep 0.5
    update_lights_via_serial_port ["\#red", "\#green", "\#blue"]
end

def boot_tree
    update_lights_via_serial_port ["\#red"]
    sleep 0.2
    update_lights_via_serial_port ["\#red", "\#green"]
    sleep 0.2
    update_lights_via_serial_port ["\#red", "\#green", "\#blue"]
    sleep 0.2

    update_lights_via_serial_port []
    sleep 0.1
    update_lights_via_serial_port ["\#red", "\#green", "\#blue"]
    sleep 0.1
    update_lights_via_serial_port []
    sleep 0.1
    update_lights_via_serial_port ["\#red", "\#green", "\#blue"]
    sleep 0.1
    update_lights_via_serial_port []
    sleep 0.1
    update_lights_via_serial_port ["\#red", "\#green", "\#blue"]

    sleep 0.2
    update_lights_via_serial_port ["\#red", "\#green"]
    sleep 0.2
    update_lights_via_serial_port ["\#red"]
    sleep 0.2
    update_lights_via_serial_port []

    sleep 0.2
    update_lights_via_serial_port ["\#red", "\#green", "\#blue"]
end

def create_mask(tags)
    mask = 0
    if tags.include? "\#red"
        mask |= RED_MASK
    end

    if tags.include? "\#green"
        mask |= GREEN_MASK
    end

    if tags.include? "\#blue"
        mask |= BLUE_MASK
    end

    mask
end

#do a double-flash so we know it's not a tweet
def update_random
    colours = ["\#red", "\#green", "\#blue"]
    tags = colours.shuffle[0..Random.rand(colours.size)]

    update_lights_via_serial_port(tags)
    sleep 0.1
    update_lights_via_serial_port([])
    sleep 0.1
    update_lights_via_serial_port(tags)

    tags
end

def update_lights_via_serial_port(tags)
    device = "/dev/tty.usbmodem1421"
    baud_rate = 9600
    data_bits = 8
    stop_bits = 1
    parity = SerialPort::NONE

    port = SerialPort.new(device, baud_rate, data_bits, stop_bits, parity)

    last_updated = Time.now
    port.write create_mask tags
end

def to_sentence(array = nil)
    return array.first.to_s if array.nil? or array.length <= 1
    "#{array[0..-2].join(", ")} and #{array[-1]}"
end

def update_if_new(db, tweet, client)
    result = db.execute "SELECT COUNT(*) FROM Tweets WHERE Id = #{tweet.id}"
    count = result[0][0].to_i

    unless (count > 0)
        log tweet
        p "Adding #{tweet.id}"
        db.execute "INSERT INTO Tweets (Id, Name) VALUES('#{tweet.id}', '#{tweet.user.screen_name}')"

        tags = find_all_tags tweet.full_text

        if tags.size > 0
            update_lights_via_serial_port tags

            client.update("#{greeting} #{status} #{to_sentence(tags)} #{reason} @#{tweet.user.screen_name}!")

            # little pause in case there are a few to deal with
            sleep 10
        # else
        #     NEEDS TO TRACK ID OR IT'LL SPAM USER. MAYBE BEST TO JUST IGNORE IT.
        #     client.update("@#{tweet.user.screen_name} I'm sorry, I didn't understand. You can pick any of \#red, \#green or \#blue.")
        end
    end
end

def log(tweet)
    p "Tweet ID: #{tweet.id} from @#{tweet.user.screen_name} [#{tweet.user.id}] at #{tweet.created_at}"
end

begin

    db = SQLite3::Database.new "bbcradiotree.sqlite3"
    db.execute "CREATE TABLE IF NOT EXISTS Tweets(Id INTEGER PRIMARY KEY, Name TEXT)"

    boot_tree

    loop do
        begin
            client = Twitter::REST::Client.new do |config|
                config.consumer_key        = "consumer_key"
                config.consumer_secret     = "consumer_secret"
                config.access_token        = "access_token"
                config.access_token_secret = "access_token_secret"
            end

            p "Polling twitter: [#{Time.now.to_s}]"

            tweets = client.mentions_timeline

            tweets.each do |tweet|
                tags = find_all_tags(tweet.full_text)
                update_if_new(db, tweet, client)
            end

            p "Last updated: #{last_updated}"

            if ((Time.now - last_updated) > 180)
                update_to_default
            end

            sleep(30)

        rescue Twitter::Error::TooManyRequests => error
            puts "Too many requests! Sleeping for #{error.rate_limit.reset_in} seconds"
            sleep(error.rate_limit.reset_in + 1)
            last_updated = Time.now # make the last updated to now so we don't auto-update if requests are waiting.
        end

    end

rescue SQLite3::Exception => e
    puts e

ensure
    db.close if db
end
