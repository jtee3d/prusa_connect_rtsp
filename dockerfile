# Use Alpine as the base image
FROM alpine:3.19.0

# Copy upload.sh
COPY upload.sh upload.sh

# Install bash, curl, and ffmpeg
RUN apk add --no-cache bash curl ffmpeg

# Set the entrypoint
ENTRYPOINT ["/bin/bash", "/upload.sh"]