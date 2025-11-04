# Set log level from 1 - 5 (critical, important, normal, information, debug)
settings.log.level.set(3)

# Enable a telnet control socket on port 1908
settings.server.telnet := true
settings.server.telnet.port := 1908
settings.server.telnet.bind_addr := "0.0.0.0"

# Grab month for seasonal streams
month = time.local().month

# Helper function for creating Icecast outputs
def make_stream(name) =
  lname  = string.lowercase(name)
  folder = "/music/" ^ name
  mount  = "/" ^ lname
  desc   = name ^ " Radio"

  source = mksafe(random([playlist(id=lname, reload_mode="watch", folder)]))

  # Compression
  source = compress(source, attack = 2.0, gain = 0.0, knee = 13.0, ratio = 2.0, release = 12.3, threshold = -18.0)

  # Normalization
  # source = normalize(source, gain_max = 6.0, gain_min = -6.0, target = -16.0, threshold = -65.0)

  # This assures all tracks are played at the same loudness,
  # using the ReplayGain value stored in the audio files.
  source = amplify(1., override="replaygain_track_gain", source)

  output.icecast(
    %mp3(id3v2=true, bitrate=128),
    format = "audio/mpeg",
    host = "icecast",
    port = 8000,
    password = "hunter2",
    mount = mount,
    name = name,
    description = desc,
    send_icy_metadata = null,
    source
  )
end

# This is where you initialize your radio mount points.
# These should correspond with the subfolders in ./music

# make_stream("80s")
# make_stream("Coffeeshop")
# make_stream("Jazz")

# Optional: Seasonal streams

# This mount point is only active in October
if month == 10 then
  make_stream("Halloween")
end

# This mount point is only active in December
if month == 12 then
  make_stream("Christmas")
end
