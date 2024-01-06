#!/bin/bash

trap "echo SIGINT received, exiting...; exit 0" INT


echo "     ██╗████████╗███████╗███████╗██████╗ ██████╗"
echo "     ██║╚══██╔══╝██╔════╝██╔════╝╚════██╗██╔══██╗"
echo "     ██║   ██║   █████╗  █████╗   █████╔╝██║  ██║"
echo "██   ██║   ██║   ██╔══╝  ██╔══╝   ╚═══██╗██║  ██║"
echo "╚█████╔╝   ██║   ███████╗███████╗██████╔╝██████╔╝"
echo " ╚════╝    ╚═╝   ╚══════╝╚══════╝╚═════╝ ╚═════╝ "
echo ""
echo "This script sends snapshots of RTSP streams to Prusa Connect."
echo ""
: "${PRUSA_URL:=https://webcam.connect.prusa3d.com/c/snapshot}"
: "${RTSP_URLS:=}"
: "${TOKENS:=}"


RTSP_URLS=$(echo "$RTSP_URLS" | tr -d ' ')
TOKENS=$(echo "$TOKENS" | tr -d ' ')
FRAME_CAPTURE_DELAY=${FRAME_CAPTURE_DELAY:-1}
CAMERA_CYCLE_DELAY=${CAMERA_CYCLE_DELAY:-1}



IFS="," read -ra RTSP_URLS <<< "$RTSP_URLS"
IFS="," read -ra TOKENS <<< "$TOKENS"

FINGERPRINTS=()
for i in $(seq 1 ${#RTSP_URLS[@]}); do
    FINGERPRINTS+=($(printf "camera%010d" $i))
done
echo "Input variables:"
for i in "${!RTSP_URLS[@]}"; do
        echo "Camera $((i + 1)), ${RTSP_URLS[$i]}, ${TOKENS[$i]}"
done

while true; do
    for i in "${!RTSP_URLS[@]}"; do
        echo "Processing camera: $((i + 1))"
        echo "RTSP URL: ${RTSP_URLS[$i]}"
        echo "Token: ${TOKENS[$i]}"
        echo "Fingerprint: ${FINGERPRINTS[$i]}"
        echo "------"
        ffmpeg \
            -loglevel error \
            -y \
            -rtsp_transport tcp \
            -i "${RTSP_URLS[$i]}" \
            -f image2 \
            -vframes 1 \
            -pix_fmt yuvj420p \
            output_$i.jpg
        if [ $? -eq 0 ]; then
            curl -X PUT "$PRUSA_URL" \
                -H "accept: */*" \
                -H "content-type: image/jpg" \
                -H "fingerprint: ${FINGERPRINTS[$i]}" \
                -H "token: ${TOKENS[$i]}" \
                --data-binary "@output_$i.jpg" \
                --no-progress-meter \
                --compressed
        else
            echo "FFmpeg returned an error for camera $((i + 1))."
        fi
        sleep "$FRAME_CAPTURE_DELAY"
    done
    sleep "$CAMERA_CYCLE_DELAY"
done
