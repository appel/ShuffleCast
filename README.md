# ShuffleCast

ShuffleCast is a dockerized 'radio-in-a-box' which creates internet radio streams from mp3s in subfolders. It aims to provide a super simple, barebones setup for running a multi-stream internet radio station using Docker Compose. It uses Icecast as the streaming server and Liquidsoap as a dynamic "auto-DJ" that creates streams from music folders. You can then use these streams anywhere you like: in any app that accepts stream URLs (like [VLC](https://www.videolan.org/vlc/), [Foobar2000](https://www.foobar2000.org/), [RadioTray](https://github.com/ebruck/radiotray-ng), [Eter](https://apps.apple.com/us/app/eter-streaming-internet-radio/id1523221566), [GaGa]https://github.com/Beluki/GaGa) (RIP Carlos) or [Winamp](https://winamp.com/player)), in your Home Assistent set-up, or directly in your browser.

#### Why did I build this?

First of all, I did not 'build' anything. :) All credit goes to the devs and maintainers of [Icecast](https://github.com/pltnk/docker-icecast2) and [Liquidsoap](https://github.com/pltnk/docker-liquidsoap). What I did was throw a few config files together.

I wanted a super simple way to shuffle my own music on my own smart speakers. Using Plex to cast music to my speaker group was a frustratingly jittery mess, but I noticed I never had that issue when playing internet radio streams, like [KEXP](https://www.kexp.org/streaming-urls/) or [WNYC](https://www.wnyc.org/audio/other-formats/). I first tried [Azuracast](https://www.azuracast.com/), which works really well and is a truly awesome project with loads of configuration options, but managing it is a little involved and it was a little resource heavy on my hardware. I wanted something simple and lightweight, something I could run in my local network. Ergo, ShuffleCast! I've been using it for a few months and it has been working so well for me that I figured I'd share it here in case it's useful to others.


## Features

  * **Dockerized:** Runs both Icecast and Liquidsoap in separate containers.
  * **Dynamic Streams:** The Liquidsoap script automatically creates a separate stream for each subfolder you create (e.g., `music/80s`, `music/Jazz`) and shuffles the mp3 files. Just copy your mp3s to each folder and Bob's your proverbial uncle!
  * **Audio Processing:** Includes built-in optional compression and normalization.
  * **Consistent volume:** Uses the `replaygain_track_gain` metatag (if available) for consistent volume.
  * **Seasonal Streams:** The configuration includes logic to automatically enable "Halloween" and "Christmas" streams during October and December, respectively (if the corresponding folders exist).
  * **Easy Setup:** Get up and running by adding your music and running one command.
  * **Easy Control:** Comes with a bash script to control ShuffleCast (start, restart, update, skip, echo, run & logs).

## How it works

This whole shindig consists of two services managed by `docker-compose.yml`:

1.  **`icecast`**: The public-facing internet radio server. It receives audio from Liquidsoap and serves it to listeners.
2.  **`liquidsoap`**: The "source" or "auto-DJ". It scans the `./music` directory for subfolders, creates a shuffled playlist for each one, processes the audio, and feeds it to Icecast.

## Prerequisites

  * Docker
  * Docker Compose
  * A fistful of mp3s

## Setup

### 1\. Directory structure

Your project must have the following directory structure. The `docker-compose.yml` file relies on these specific paths.

  * `config/`: Holds your configuration files.
  * `music/`: This is your music library. Liquidsoap will turn each subfolder (`80s`, `Jazz`, etc.) into its own stream.

```
.
├── config/
│   ├── icecast.xml
│   └── liquidsoap.liq
├── music/
│   ├── 80s/
│   │   ├── take-on-me.mp3
│   │   └── ...
│   ├── Jazz/
│   │   ├── take-5.mp3
│   │   └── ...
│   └── Halloween/
│   │   ├── thriller.mp3
│   │   └── ...
└── docker-compose.yml
```

### 2\. Add your ditties and jams

Copy your music files (preferably `.mp3` with a fixed bitrate and, optionally, ReplayGain Track Gain metadata) into subfolders within the `music/` directory, e.g.:

  * `80s`
  * `Jazz`
  * `Lo-Fi`
  * `MusicForCats`
  * `Halloween` (only active during the month of October)
  * `Christmas` (only active during the month of December)

These subfolders can then be turned into their own stream by adding them to the `liquidsoap.liq` config file, for example:

```
...
make_stream("80s")
make_stream("Jazz")
make_stream("Lo-Fi")
make_stream("MusicForCats")

if month == 10 then
  make_stream("Halloween")
end

if month == 12 then
  make_stream("Christmas")
end
...
```

### 3\. Launch ShuffleCast

From the root directory (where `docker-compose.yml` is), run:

```bash
docker compose up -d
```

ShuffleCast should now be running\!

To see what Liquidsoap is up to, run:

```bash
docker compose logs "liquidsoap" -f
```

### ShuffleCast remote

From the root directory (where `docker-compose.yml` is), run:

```bash
sudo chmod +x ./shufflecast.sh
```

Now you can run commands from the terminal, like so

```bash
./shufflecast.sh skip 80s # Skip current track on 80s mountpoint
./shufflecast.sh restart # Restart both containers (optional parameter: icecast|liquidsoap)
./shufflecast.sh update # Update both containers
./shufflecast.sh logs # Show logs for both containers (optional parameter: icecast|liquidsoap)
./shufflecast.sh run help # Run raw command
```

You can also skip songs directly:

```bash
bash -c 'echo "80s.skip" > /dev/tcp/localhost/1908'
docker exec liquidsoap bash -c 'echo "80s.skip" > /dev/tcp/localhost/1908'
```

This is handy if you want to integrate it with [Home Assistant](https://www.home-assistant.io/), for example:

```yaml
# configuration.yaml
switch:
  - platform: telnet
    name: "Skip 80s track"
    resource: <your-server-ip> # Replace this with your server's IP address
    port: 1908
    command_on: "80s.skip"
    timeout: 0.5
```

After adding this and restarting HA, you will have a "Skip 80s track" switch. When you turn it "on", it just sends the coffeeshop.skip command and then immediately turns itself back "off", acting as a perfect "skip" button.

### Stream URLs

Your streams will be available at the mount points defined in `liquidsoap.liq`. Based on the previous examples, your stream URLs would be:

  * `http://<your-server-ip>:1907/80s`
  * `http://<your-server-ip>:1907/jazz`
  * `http://<your-server-ip>:1907/lo-fi`
  * `http://<your-server-ip>:1907/musicforcats`
  * `http://<your-server-ip>:1907/halloween` (only in Oct)
  * `http://<your-server-ip>:1907/christmas` (only in Dec)

### Adding more songs

To add more songs to your streams you can simply drop more mp3s into your subfolders. Liquidsoap will pick them up automatically.

### Adding a new stream

1.  Create a new music folder (e.g., `music/Grunge`).
2.  Edit `config/liquidsoap.liq` and add a new line near the bottom of the file:
    ```liquidsoap
    make_stream("Grunge")
    ```
3.  Restart the Liquidsoap container to apply the changes:
    ```bash
    docker compose restart liquidsoap
    ```

Your new stream will be available at `http://<your-server-ip>:1907/grunge`.

### Here be dragons!

I made this to scratch a personal itch. I'm by no means an Icecast, Liquidsoap, and/or Docker expert, so there is probably loads of room for improvement. Also note that this intended to be used locally, within your local network (which considering the bandwidth implications of opening it up to the world is probably for the best).

That being said, it's been running for a few months now without any issues. No more jitters!

Find any bugs? Or did you change anything to make it better? Please let me know and I'll consider adding it! Keep in mind that the goal is simplicity.
