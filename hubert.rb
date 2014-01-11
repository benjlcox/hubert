puts 'Requiring Twilio...'
require 'twilio-ruby'
puts 'Requiring Hue...'
require 'hue'
puts 'Requiring Sinatra...'
require 'sinatra'
puts 'Requiring Sinatra/activerecord...'
require 'sinatra/activerecord'
require_relative 'env.rb' #API Credentials

#set :bind, '192.168.2.25'

#Database loading and basic models

puts "Connecting to Database..."
ActiveRecord::Base.establish_connection(  
  :adapter => "mysql",  
  :host => "localhost",  
  :database => "hubert",
  :username => ENV['sql_username'],
  :password => ENV['sql_password']
) 

puts "Building models..."
class Schedule < ActiveRecord::Base
  validates_presence_of :command
end

puts 'Defining helpers...'
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
    when 'db'
      @records = Schedule.all
      @records.each do |r|
        reply(r.to_s)
      end
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
  def schedule(time_num,time_unit,command, requester)
    actual_command = ""
    (3..command.length - 1).each do |n|
      actual_command += "#{command[n]} "
    end
    time = timely(time_num,time_unit)
    Schedule.create({:time => time, :command => actual_command.chomp(" "), :requester => requester})
  end

  def timely(time_num,time_unit)
    current_time = Time.now
    case time_unit
    when "second", "seconds"
      future_time = current_time + time_num.to_i
    when "minute","minutes"
      future_time = current_time + (time_num.to_i * 60)
    when "hour","hours"
      future_time = current_time + ((time_num.to_i * 60) * 60)
    end
  end

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
end

#Routes

puts 'Defining routes...'
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
    schedule(sms[1],sms[2],sms,params[:From])
    reply("I have scheduled your command for #{sms[1]} #{sms[2]} from now.")
  else
    reply("Sorry, don't know what the means")
  end
end
