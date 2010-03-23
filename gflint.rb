#!/usr/bin/env ruby
require 'rubygems'
require "uri"
require 'twitter/json_stream'
require 'json'
require "httparty"

@last_message = 'gflint'

def notify(header,msg,options = {})
  `notify-send #{options[:img]} #{options[:delay]} '#{header}' '#{msg}'`
end

def monitor_room(options,room_name,room_uri)

  EventMachine::run do
    stream = Twitter::JSONStream.connect(options)
    #users =  Connection.get(room_uri)
    #puts users.inspect
    stream.each_item do |item|
      msg = JSON.parse(item)
      notify( "#{room_name}:", msg["body"].to_s ) unless msg["body"].nil?
    end
    
    stream.on_error do |message|
      notify "ERROR: ", "#{message.inspect}"
    end
   
    stream.on_max_reconnects do |timeout, retries|
      puts "Tried #{retries} times to connect."
      exit
    end
  end
  
end

config = YAML::load_file("#{ENV['HOME']}/.gflintrc")

config.keys.each do |account_name|
  rooms = config[account_name][:rooms]
  if rooms && rooms.size > 0
    rooms.keys.each do |room_name|
      room_uri =  "http://#{account_name}.campfirenow.com/room/#{rooms[room_name][:id]}.json"
      options = {
        :path => "/room/#{rooms[room_name][:id]}/live.json",
        :host => 'streaming.campfirenow.com',
        :auth => "#{config[account_name][:token]}:x"
      }
      
      #puts room.inspect
      monitor_room(options,room_name,room_uri)
    end
  end
end
