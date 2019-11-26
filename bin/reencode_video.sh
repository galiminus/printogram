#!/bin/sh

ffmpeg -i "$1" -an -c:v libx264  -movflags faststart -vf scale=1280:720 -crf 28 -preset veryslow app/assets/images/home.mp4