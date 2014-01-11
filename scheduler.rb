puts 'Require dependencies...'
require 'mysql'
require 'open-uri'
require 'httparty'
require 'sinatra/activerecord'
require_relative 'env.rb'

#Connect and load database
puts "Connecting to database..."
ActiveRecord::Base.establish_connection(  
  :adapter => "mysql",  
  :host => "localhost",  
  :database => "hubert",
  :username => ENV['sql_username'],
  #:password => ""
  :password => ENV['sql_password']
) 

class Schedule < ActiveRecord::Base
  validates_presence_of :command
end

#Start the app loop

puts "Starting Scheduler..."
loop do
  #Get all of the unexecuted commands
  print "Listening...\r"
  @Tasks = Schedule.where(executed: false)
  @Tasks.each do |task|
    if Time.now >= task.time
      puts "Sending message to #{task.requester} at #{Time.now}"
      encoded_command = URI::encode(task.command)
      request = HTTParty.get("http://192.168.2.25:4567/sms?Body=#{encoded_command}&From=#{task.requester}&To=6137071125")
      Schedule.update(task.id, :executed => true)
    end
  end
  sleep 2
  print "Listening***\r"
  sleep 2
end