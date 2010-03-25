#!/usr/bin/env ruby
require 'rubygems'
require "uri"
require 'twitter/json_stream'
require 'json'
require "broach"
require 'pathname'

def notify(header,msg,options = {})
  `notify-send #{options[:img]} #{options[:delay]} "#{header}" "#{msg}"`
end

def monitor_room(options,room_name,account_name, config)
  Broach.settings = { 'account' => account_name, 'token' => config[account_name][:token],'use_ssl'=>config[account_name][:ssl]}
  pwd  = File.dirname(File.expand_path(__FILE__))
  icon_path = "#{pwd}/campfire-logo.png"
  # /room/#{id}/join.xml
  begin
    Broach.session.post("/room/#{room_name}/join.xml",{})
  rescue
    status = $!
  end
  EventMachine::run do
    stream = Twitter::JSONStream.connect(options)
    
    stream.each_item do |item|
      msg = JSON.parse(item)
      user = Broach.session.get("/users/#{msg["user_id"]}") unless msg["user_id"].nil?
      notify( "#{user.first[1]['name']}:", msg["body"].gsub('"','\\\\"'), {:img => "-i #{icon_path}"} ) unless msg["body"].nil?
      #puts icon_path
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
      monitor_room(options,rooms[room_name][:id],account_name,config)
    end
  end
end
