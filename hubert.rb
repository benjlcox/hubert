require 'sinatra'
require 'twilio-ruby'
require 'hue'
require_relative 'env.rb' #API Credentials
require_relative 'loop.rb'
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
      reply("Hello - Lights (on,off,up,down,status,color) - Nest - Info (ip,instructions)")
    else
      error(sms[1])
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
      if hue_colour(sms[2].to_i) === true
        reply("I have set the lights to #{sms[2]}")
      else
        reply("I need a hue between 0 and 65535. Remember, both 0 and 65535 are red, 25500 is green and 46920 is blue")
      end
    when 'status'
      info = hue_status
      info.each do |i|
        reply(i)
      end
    when 'preset'
      if hue_preset(sms[2]) === true
        reply("Lights have been changed to preset #{sms[2]}")
      else
        reply("I don't know the #{name} preset")
      end
    when 'flow'
      hue_flow(sms[2])
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

  def hue_colour(colour)
    if colour >= 0 && colour <= 65535
      @hue_client.lights.each do |light|
        light.set_state({:hue => colour})
      end
      return true
    else
      return false
    end
  end

  def hue_preset(name)
    hue_presets = {:relax => [13157,13157,13157], :lounge => [27156,53599,43128]}
    preset = hue_presets[name.to_sym]
    if !preset.nil?
      @hue_client.lights.each do |light|
        light.set_state({:hue => preset[light.id.to_i - 1]})
      end
      return true
    else
      return false
    end
  end

  def hue_flow(state)
    Thread.new{
      until state === false
        h = @hue_client.lights[Random.rand(0..2)]
        c = Random.rand(0..65535)
        t = Time.now
        begin
          puts "Light #{h.id} changing to #{c} at #{Time.now}"
          h.set_state({:hue => c, :transitiontime => 50})
        rescue
          puts "Something fucky happened => Light #{h.id} changing to #{c} at #{Time.now}"
        end
        sleep 4 
      end
    }
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
