# ShuffleCast

ShuffleCast is a 'radio-in-a-box' which creates internet radio streams from mp3s in subfolders. It aims to provide a super simple, barebones setup for running a multi-stream internet radio station using Docker Compose. It uses Icecast as the streaming server and Liquidsoap as a dynamic "auto-DJ" that creates streams from music folders.

## Features

  * **Dockerized:** Runs both Icecast and Liquidsoap in separate containers.
  * **Dynamic Streams:** The Liquidsoap script automatically creates a separate stream for each subfolder you create (e.g., `music/80s`, `music/Jazz`) and shuffles the mp3 files. Just copy your mp3s to each folder and Bob's your proverbial uncle!
  * **Audio Processing:** Includes built-in compression and normalization. No crossfading as of yet.
  * **Seasonal Streams:** The configuration includes logic to automatically enable "Halloween" and "Christmas" streams during October and December, respectively (if the corresponding folders exist).
  * **Easy Setup:** Get up and running by adding your music and running one command.

## Why did I build this?

I wanted a simple way to play my own music on my own smart speakers. Using Google's cast was a frustratingly jittery mess, but I noticed I never had that issue when playing internet radio streams, like KEXP or my local NPR affiliate. I first tried [Azuracast](https://www.azuracast.com/), which worked great and is a truly awesome project, but managing it is a little involved. I wanted something simple and lightweight that I could run on my local network. Ergo, ShuffleCast! Sharing it here in case it is useful to anyone else.

## How It Works

This setup consists of two services managed by `docker-compose.yml`:

1.  **`icecast`**: The public-facing internet radio server. It receives audio from Liquidsoap and serves it to listeners.
2.  **`liquidsoap`**: The "source" or "auto-DJ". It scans the `./music` directory for subfolders, creates a playlist for each one, processes the audio, and feeds it to Icecast.

The two containers communicate over a dedicated Docker network called `radio`.

## Prerequisites

  * Docker
  * Docker Compose

## Setup Instructions

### 1\. Directory Structure

Before you begin, your project must have the following directory structure. The `docker-compose.yml` file relies on these specific paths.

```
.
├── config/
│   ├── icecast.xml
│   └── liquidsoap.liq
├── music/
│   ├── 80s/
│   │   ├── take-on-me.mp3
│   │   └── maniac.mp3
│   ├── Jazz/
│   │   ├── take-5.mp3
│   │   └── ...
│   └── Halloween/
│   │   ├── thriller.mp3
│   │   └── ...
└── docker-compose.yml
```

  * `config/`: Holds your configuration files.
  * `music/`: This is your music library. Liquidsoap will turn each subfolder (`80s`, `Jazz`, etc.) into its own stream.

### 2\. Add Your Music

Copy your music files (preferably `.mp3` with a fixed bitrate) into subfolders within the `music/` directory, e.g.:

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


### 3\. Review Configuration (Optional)

The default configuration should wwork out of the box, but you may want to change the passwords.

  * **`docker-compose.yml`**: Exposes the Icecast server on host port `1907`. You can change the `1907` part (e.g., `"8000:8000"`) if you prefer.
  * **`config/icecast.xml`**:
      * `<source-password>`: `aaa` (Password Liquidsoap uses to connect).
      * `<admin-password>`: `bbb` (Password for the Icecast web admin).
  * **`config/liquidsoap.liq`**:
      * `password = "aaa"` (Must match the `<source-password>` in `icecast.xml`).

### 4\. Launching ShuffleCast

From the root directory (where `docker-compose.yml` is), run:

```bash
docker-compose up -d
```

ShuffleCast should now be running\!

### Stream URLs

Your streams will be available at the mount points defined in `liquidsoap.liq`. Based on the previous examples, your stream URLs would be:

  * `http://<your-server-ip>:1907/80s`
  * `http://<your-server-ip>:1907/jazz`
  * `http://<your-server-ip>:1907/lo-fi`
  * `http://<your-server-ip>:1907/musicforcats`
  * `http://<your-server-ip>:1907/halloween` (only in Oct)
  * `http://<your-server-ip>:1907/christmas` (only in Dec)

### Adding a New Stream

1.  Create a new music folder (e.g., `music/Grunge`).
2.  Edit `config/liquidsoap.liq` and add a new line near the bottom of the file:
    ```liquidsoap
    make_stream("Grunge")
    ```
3.  Restart the Liquidsoap container to apply the changes:
    ```bash
    docker-compose restart liquidsoap
    ```

Your new stream will be available at `http://<your-server-ip>:1907/grunge`.

### Changing Passwords

1.  Stop the containers: `docker-compose down`
2.  In `config/icecast.xml`, change `<source-password>` and `<admin-password>` to new, secure values.
3.  In `config/liquidsoap.liq`, change the `password = "aaa"` line to match the new `<source-password>`.
4.  Start the containers: `docker-compose up -d`

### Proceed with caution!

I'm by no means an Icecast, Liquidsoap, and/or Docker expert, so there might be room for improvement. I only use these streams within my local network (which considering the bandwidth implications of opening it to the world is probably wise).

That being said, it's been running locally for a few months now without any issues. No more jitters!

Find any bugs? Or did you change anything to make it better? Please let me know and I'll consider adding it!
