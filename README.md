## What is prusa-connect-rtsp?
Inspired by [nunofgs on GitHub](https://gist.github.com/nunofgs/84861ee453254823be6b069ebbce9ad2) and with the help of [BillyAB](https://github.com/billyab), this project simplifies using RTSP cameras with [Prusa Connect](https://connect.prusa3d.com/).

FFmpeg is used to take periodic snapshots of an RTSP camera stream, then cURL is used to pass it through to the [Prusa Connect Camera API](https://connect.prusa3d.com/docs/cameras/). Snapshots are taken and sent every 10 seconds.

Personally, I have it running 5 streams from Eufy C24 Wi-Fi cameras on a single Raspberry Pi Zero 2W, without issue.

## Getting Prusa Connect Tokens
It's best to consult Prusa's official documentation, as the interface may change over time, but the steps below should point you in the right direction:
1. Open **Prusa Connect** web interface
2. On a printer dashboard, go to the **Camera** tab
3. Click **Add new other camera**
4. Give the camera a name *(optional)*
5. **Copy the token**
6. **Paste** the token in to your docker-compose file or docker command

Note: If setting up multiple cameras, the order of your RTSP URLs should match the order of your tokens.

## Usage
RTSP URLs and Prusa Connect tokens are passed through to the script using environment variables. Single RSTP URLs and tokens can be specified, or multiples can be added by separating them with a comma. Below are some examples of how to run the container using Docker Compose or the Docker CLI.

### docker compose (recommended)

```yaml
version: '3.8'
services:
  prusa_connect_rtsp:
    image: jtee3d/prusa_connect_rtsp:latest
    restart: always
    environment:
      RTSP_URLS: >
        rtsp://username:password@192.168.1.11/live0,
        rtsp://username:password@192.168.1.12/live0,
        rtsp://username:password@192.168.1.13/live0
      TOKENS: >
        5dvoIByhfG7AeODTiNNk,
        MdVaUadfw93MBdlZSlqM,
        fejnJhrhCGncXsDU0R8S
```

### docker cli

```bash
docker run \
  -e RTSP_URLS="\
rtsp://username:password@192.168.1.11/live0,\
rtsp://username:password@192.168.1.12/live0,\
rtsp://username:password@192.168.1.13/live0" \
  -e TOKENS="\
5dvoIByhfG7AeODTiNNk,\
MdVaUadfw93MBdlZSlqM,\
fejnJhrhCGncXsDU0R8S" \
  jtee3d/prusa_connect_rtsp:latest
```
## Support

If you would like to support this docker build, please feel free to buy me a coffee!

<a href="https://www.buymeacoffee.com/jtee3d" rel="nofollow noopener"> <img width="210" height="50" src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png"></a>

