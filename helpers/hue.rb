hue_client = Hue::Client.new

def hue_io(state)
  io = true unless state === "off"
  hue_client.lights.each do |light|
    light.on = io
  end
end