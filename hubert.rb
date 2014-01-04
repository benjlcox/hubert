require 'sinatra'
require 'twilio-ruby'
require 'hue'
require_relative 'env.rb' #API Credentials
require_relative 'helpers/hue.rb' #Hue action methods
require_relative 'helpers/scheduler.rb' #the Scheduler 

set :bind, '192.168.2.25'

helpers do 
  def reply(body)
    puts "Sending reply => #{body}."
		twilio_client = Twilio::REST::Client.new ENV['twilio_sid'], ENV['twilio_token']
		twilio_client.account.messages.create(:from => '+16137071125', :to => params[:From], :body => "#{body}")
  end

  def error(instruction)
    reply("Sorry, you need to tell me what to do with #{instruction}")
  end

  def nest(data)

  end

  def hue(data)
    case data[1]
    when 'on'
      hue_io('on')
      reply("I have turned on the lights")
    when 'off'
      hue_io('off')
      reply("I have turned off the lights")
    when 'status'
      #show status
      reply("The lights are something")
    else
      #else shit
      reply("Iunno, lights or something")
    end
  end
end

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

get '/log' do
  content_type :txt
  IO.popen('tail -f some.log')
end
