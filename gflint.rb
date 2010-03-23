#!/usr/bin/env ruby
require 'rubygems'
require "uri"
require 'twitter/json_stream'
require 'json'
require "broach"

@last_message = 'gflint'

def notify(header,msg,options = {})
  `notify-send #{options[:img]} #{options[:delay]} "#{header}" "#{msg}"`
end

def monitor_room(options,room_name,account_name, config)

  EventMachine::run do
    stream = Twitter::JSONStream.connect(options)
    account = config[account_name]
    #Broach.settings = { 'account' => account_name, 'token' => account[:token], 'ssl'=> account[:ssl] }
    #puts room_info
    stream.each_item do |item|
      msg = JSON.parse(item)
      user = msg["user_id"] unless msg["user_id"].nil?
      notify( "#{room_name}:", msg["body"].gsub('"','\\\\"') ) unless msg["body"].nil?
      #puts msg["body"].gsub('"','\\\\"')
    end
    
    stream.on_error do |message|
      notify "ERROR: ", "#{message.inspect}"
    end
   
    stream.on_max_reconnects do |timeout, retries|
      notify "TIMEOUT: ","Tried #{retries} times to connect."
      exit
    end
  end
  
end

config = YAML::load_file("#{ENV['HOME']}/.gflintrc")

config.keys.each do |account_name|
  rooms = config[account_name][:rooms]
  if rooms && rooms.size > 0
    rooms.keys.each do |room_name|
      
      options = {
        :path => "/room/#{rooms[room_name][:id]}/live.json",
        :host => 'streaming.campfirenow.com',
        :auth => "#{config[account_name][:token]}:x"
      }
      
      #puts room.inspect
      monitor_room(options,room_name,account_name,config)
    end
  end
end
