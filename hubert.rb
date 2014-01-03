require 'sinatra'
require 'twilio-ruby'
require 'hue'
require './env.rb'

helpers do 
	def nest(data)

	end

	def hue(data)
		case data[1]
		when 'on'
			#turn lights on
			response = "I have turned on the lights"
		when 'off'
			#turn lights off
			response = "I have turned off the lights"
		when 'status'
			#show status
			response = "The lights are something"
		else
			#else shit
			response = "Iunno, lights or something"
		end
	end

	def error(instruction)
		reply("Sorry, you need to tell me what to do with #{instruction}")
    end

    def reply(body)
    	puts "Sending response."
		sid = "AC5328128ca782cfad1d1b621ab0a894b2"
		@client = Twilio::REST::Client.new ENV['twilio_sid'], ENV['twilio_token']
		@client.account.messages.create(
			:from => '+16137071125',
	  		:to => params[:From],
	  		:body => "#{body}"
		)
    end
end

get '/sms' do
	puts "Received sms from #{params[:From]} that says #{params[:Body]} - splitting now"
	sms = params[:Body].downcase.split(" ")

	case sms[0]
	when "hello"
		reply("Good day, Sir.")
		puts 'case => Hello'
	when "lights"
		if sms[1] then hue(sms) else error("lights") end
		puts 'case => lights'
	when "nest"
		reply("Thermostat")
		puts 'case => nest'
	when "remind"
		#reminder method
		puts 'case => remind'
	when "schedule"
		#scheduler method
		puts 'case => schedule'
	else
		reply("Sorry, don't know what the means")
		puts 'case => else'
	end

	
end