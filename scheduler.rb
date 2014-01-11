require 'mysql'
require 'open-uri'
require 'httparty'
require 'sinatra/activerecord'
require_relative 'env.rb'

#Connect and load database

ActiveRecord::Base.establish_connection(  
  :adapter => "mysql",  
  :host => "localhost",  
  :database => "hubert",
  :username => ENV['sql_username'],
  :password => ENV['sql_password']
) 

class Schedule < ActiveRecord::Base
  validates_presence_of :command
end

#Twilio helper stuff

def reply(body)
	puts "Sending reply => #{body}."
	twilio_client = Twilio::REST::Client.new ENV['twilio_sid'], ENV['twilio_token']
	twilio_client.account.messages.create(:from => '+16137071125', :to => params[:From], :body => "#{body}")
end

def error(instruction)
	reply("Sorry, the following instruction was incomplete or doesn't exist: #{instruction}")
end

#Start the app loop

puts "Starting Scheduler..."

loop do
  #Get all of the unexecuted commands
  puts "Getting tasks"
  @Tasks = Schedule.where(executed: false)
  @Tasks.each do |task|
    puts "Sending message to #{task.requester}"
    encoded_command = URI::encode(task.command)
    request = HTTParty.get("http://192.168.2.25:4567/sms?Body=#{encoded_command}&From=#{task.requester}&To=6137071125")
    Schedule.update(task.id, :executed => true)
  end
  sleep 10
end