require 'sinatra/activerecord'
require 'net/http'
require_relative 'env.rb'

#Connect and load database

set :database, "sqlite3:///hubert.sqlite3"

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

loop do

  #Get all of the unexecuted commands
  @Tasks = Schedule.all(:executed => false)

  @Tasks.each do |task|
    reply()
    end
end