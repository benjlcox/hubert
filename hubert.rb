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
    reply("Sorry, the following instruction was incomplete or doesn't exist: #{instruction}")
  end

  #Core functions
  def info(sms)
    case sms[1]
    when 'ip'
      reply("My ip address is #{request.host}")
    when 'instructions'
      reply("Hello - Lights (on,off,up,down,status) - Nest - Info (ip,instructions)")
    end
  end

  def nest(sms)

  end

  def hue(sms)
    @hue_client = Hue::Client.new
    case sms[1]
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
    when 'colour', 'color'
      color = sms[2].to_i
      if color && color >= 0 && color <= 65535
        hue_color(color)
        reply("I have set the lights to #{sms[2]}")
      else
        reply("I need a hue between 0 and 65535. Remember, both 0 and 65535 are red, 25500 is green and 46920 is blue")
      end
    when 'status'
      info = hue_status
      info.each do |i|
        reply(i)
      end
    else
      error(sms[1])
    end
  end

  #Support functions
  def hue_io(state)
    if state === "on" then io = true else io = false end
    @hue_client.lights.each do |light|
      light.on = io
    end
  end

  def hue_bri(level)
    @hue_client.lights.each do |light|
      light.set_state({:bri => level})
    end
  end

  def hue_status()
    info = []
    @hue_client.lights.each do |light|
      info << "id = #{light.id} | on? = #{light.on?} | Hue = #{light.hue} | Brightness = #{light.brightness}"
    end
    return info
  end

  def hue_color(color)
    @hue_client.lights.each do |light|
      light.set_state({:hue => color})
    end
  end

  def hue_preset(name)
    
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
  when "info"
    if sms[1] then info(sms) else error("info") end
	when "remind"
		#reminder method
	when "schedule"
		#scheduler method
	else
		reply("Sorry, don't know what the means")
	end
end
