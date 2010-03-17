#!/usr/bin/env ruby
require 'rubygems'
require 'broach'

@last_message = 'gflint'

def notify(header,msg,options = {})
  `notify-send #{options[:img]} #{options[:delay]} '#{header}' '#{msg}'`
end

def monitor_room(room)
  
  data = Broach.session.get("/room/#{room.id.to_i}/transcript")
  if @last_message == 'gflint'
    @last_message = data["messages"].last
  end
  last_index = data['messages'].index(@last_message)
  msgs = data['messages'].delete_if{|a| data['messages'].index(a) < last_index}
  
  if @last_message != data["messages"].last
    msgs.each do |msg|
      user = Broach.session.get("/users/#{msg['user_id']}")
      notify(user.first[1]['name'], msg["body"])
    end
  end
  
  @last_message = data["messages"].last
  sleep(5)
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
    end
  end
end

threads.each { |t| t.join }
