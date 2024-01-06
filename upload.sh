#!/bin/bash

trap "echo SIGINT received, exiting...; exit 0" INT

echo "     ██╗████████╗███████╗███████╗██████╗ ██████╗"
echo "     ██║╚══██╔══╝██╔════╝██╔════╝╚════██╗██╔══██╗"
echo "     ██║   ██║   █████╗  █████╗   █████╔╝██║  ██║"
echo "██   ██║   ██║   ██╔══╝  ██╔══╝   ╚═══██╗██║  ██║"
echo "╚█████╔╝   ██║   ███████╗███████╗██████╔╝██████╔╝"
echo " ╚════╝    ╚═╝   ╚══════╝╚══════╝╚═════╝ ╚═════╝ "
echo ""
echo "This script sends snapshots of RTSP and MJPEG streams to Prusa Connect."
echo ""
: "${PRUSA_URL:=https://webcam.connect.prusa3d.com/c/snapshot}"
: "${RTSP_URLS:=}"
: "${CAMERA_URLS:=}"
: "${TOKENS:=}"

if [ -n "$RTSP_URLS" ]; then
    echo "Detected use of RTSP_URLS environment variable. Use CAMERA_URLS instead."
    CAMERA_URLS=$RTSP_URLS
fi

CAMERA_URLS=$(echo "$CAMERA_URLS" | tr -d ' ')
TOKENS=$(echo "$TOKENS" | tr -d ' ')
FRAME_CAPTURE_DELAY=${FRAME_CAPTURE_DELAY:-1}
CAMERA_CYCLE_DELAY=${CAMERA_CYCLE_DELAY:-1}
CONNECTION_TIMEOUT_DELAY=${CONNECTION_TIMEOUT_DELAY:-5}

IFS="," read -ra CAMERA_URLS <<< "$CAMERA_URLS"
IFS="," read -ra TOKENS <<< "$TOKENS"

FINGERPRINTS=()
for i in $(seq 1 ${#CAMERA_URLS[@]}); do
    FINGERPRINTS+=($(printf "camera%010d" $i))
done

echo "Input variables:"
for i in "${!CAMERA_URLS[@]}"; do
    echo "Camera $((i + 1)), URL: ${CAMERA_URLS[$i]}, ${TOKENS[$i]}"
done

while true; do
    for i in "${!CAMERA_URLS[@]}"; do
        echo "Processing camera: $((i + 1))"
        echo "URL: ${CAMERA_URLS[$i]}"
        echo "Token: ${TOKENS[$i]}"
        echo "Fingerprint: ${FINGERPRINTS[$i]}"
        echo "------"
        if [[ ${CAMERA_URLS[$i]} == *"rtsp"* ]]; then
            ffmpeg \
                -loglevel error \
                -y \
                -rtsp_transport tcp \
                -i "${CAMERA_URLS[$i]}" \
                -f image2 \
                -vframes 1 \
                -pix_fmt yuvj420p \
                -timeout "$CONNECTION_TIMEOUT_DELAY" \
                output_$i.jpg
        else
            ffmpeg \
                -loglevel error \
                -y \
                -i "${CAMERA_URLS[$i]}" \
                -f image2 \
                -vframes 1 \
                -pix_fmt yuvj420p \
                -timeout "$CONNECTION_TIMEOUT_DELAY" \
                output_$i.jpg
        fi

        if [ $? -eq 0 ]; then
            curl -X PUT "$PRUSA_URL" \
                -H "accept: */*" \
                -H "content-type: image/jpg" \
                -H "fingerprint: ${FINGERPRINTS[$i]}" \
                -H "token: ${TOKENS[$i]}" \
                --data-binary "@output_$i.jpg" \
                --no-progress-meter \
                --compressed \
                --max-time "$CONNECTION_TIMEOUT_DELAY"
        else
            echo "FFmpeg returned an error for camera $((i + 1))."
        fi
        sleep "$FRAME_CAPTURE_DELAY"
    done

    sleep "$CAMERA_CYCLE_DELAY"
done
