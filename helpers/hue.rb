hue_client = Hue::Client.new

def hue_io(state)
  io = state === 'on'
  hue_client.lights.each do |light|
    light.on = io
  end
end