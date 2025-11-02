# 1: critical
# 2: important
# 3: normal
# 4: information
# 5: debug
settings.log.level.set(1)

# Grab month for seasonal streams
month = time.local().month

# Helper function for creating Icecast outputs
def make_stream(name) =
  lname  = string.lowercase(name)
  folder = "/music/" ^ name
  mount  = "/" ^ lname
  desc   = name ^ " Radio"

  source = mksafe(random([playlist(reload_mode="watch", folder)]))

  # Compression
  source = compress(source, attack = 2.0, gain = 0.0, knee = 13.0, ratio = 2.0, release = 12.3, threshold = -18.0)

  # Normalization
  source = normalize(source, gain_max = 6.0, gain_min = -6.0, target = -16.0, threshold = -65.0)

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

# Core streams - these should correspond with the subfolders in ./music

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
