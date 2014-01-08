require 'data_mapper'
require 'net/http'
require_relative 'env.rb'

#Connect and load database

DataMapper.setup(:default, 'sqlite:///Users/Ben/hubert/hubert_db.db')

class Schedule
  include DataMapper::Resource

  property :id,         Serial    
  property :time,       Text    
  property :command,    Text      
  property :requester,  Text  
  property :executed,   Boolean
end

DataMapper.finalize

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

loop do

  #Get all of the unexecuted commands
  @Tasks = Schedule.all(:executed => false)

  @Tasks.each do |task|
    if Time.now > task.time
      uri = URI('http://localhost:4567/sms')
      uri.query = URI.encode_www_form({ :Body => task.command,:From => task.requester })
      Net::HTTP.get(uri)
    end
end