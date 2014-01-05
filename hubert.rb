require 'sinatra'
require 'twilio-ruby'
require 'hue'
require_relative 'env.rb' #API Credentials
require_relative 'helpers/scheduler.rb' #the Scheduler 

#set :bind, '192.168.2.25'

helpers do 

  #SMS Replies
  def reply(body)
    puts "Sending reply => #{body}."
		twilio_client = Twilio::REST::Client.new ENV['twilio_sid'], ENV['twilio_token']
		twilio_client.account.messages.create(:from => '+16137071125', :to => params[:From], :body => "#{body}")
  end

  def error(instruction)
    reply("Sorry, you need to tell me what to do with #{instruction}")
  end

  #Core functions
  def nest(data)

  end

  def hue(data)
    @hue_client = Hue::Client.new
    case data[1]
    when 'on'
      hue_io('on')
      reply("I have turned on the lights")
    when 'off'
      hue_io('off')
      reply("I have turned off the lights")
    when 'up'
      hue_bri(255)
      reply("I have turned the lights up")
    when 'down'
      hue_bri(128)
      reply("I have turned the lights down")
    when 'status'
      #show status
      reply("The lights are something")
    else
      #else shit
      reply("Iunno, lights or something")
    end
  end

  #Support functions
  def hue_io(state)
    io = true unless state === "off"
    @hue_client.lights.each do |light|
      light.on = io
    end
  end

  def hue_bri(level)
    @hue_client.lights.each do |light|
      light.set_state({:bri => level})
    end
  end
end

#Routes

get '/sms' do
	puts "Received sms from #{params[:From]} that says #{params[:Body]}"
	sms = params[:Body].downcase.split(" ")

  case sms[0]
	when "hello"
		reply("Good day, Sir.")
	when "lights"
		if sms[1] then hue(sms) else error("lights") end
	when "nest"
		reply("Thermostat")
	when "remind"
		#reminder method
	when "schedule"
		#scheduler method
	else
		reply("Sorry, don't know what the means")
	end
end
