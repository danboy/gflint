#!/usr/bin/env ruby
require 'rubygems'
require 'broach'
require 'yaml'

@last_message = 'gflint'

def notify(header,msg,options = {})
  `notify-send #{options[:img]} #{options[:delay]} '#{header}' '#{msg}'`
end

def monitor_room(room)
  
  data = Broach.session.get("/room/#{room.id.to_i}/transcript")
  if @last_message != data["messages"].last
    user = Broach.session.get("/users/#{data['messages'].last['user_id']}")
    notify(user.first[1]['name'], data["messages"].last["body"])
  end
  
  @last_message = data["messages"].last
  sleep(10)
  monitor_room(room)
end

config = YAML::load_file("#{ENV['HOME']}/.gflintrc")
threads = []
config.keys.each do |account_name|
  rooms = config[account_name][:rooms]
  if rooms && rooms.size > 0
    Broach.settings = { 'account' => account_name, 'token' => config[account_name][:token],'use_ssl'=>config[account_name][:ssl]}
    rooms.keys.each do |room_name|
      room = Broach::Room.find_by_name(room_name)
      threads << Thread.new(room) do |r|
          monitor_room(r)
      end
      #room.speak("Posting to "+room_name.to_s+" from gflint")
    end
  end
end

threads.each { |t| t.join }
