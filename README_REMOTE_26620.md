# docker-nginx-rtmp-nvidia
A Dockerfile installing NGINX, nginx-rtmp-module and FFmpeg from source with
default settings for HLS live streaming, with NVIDIA hardware acceleration. Built on Ubuntu.

* Nginx 1.17.1 (compiled from source)
* nginx-rtmp-module 1.2.1 (compiled from source)
* ffmpeg 4.2.2 (compiled from source)
* Default HLS settings (See: [nginx.conf](nginx.conf))
* Currently set up for H264 streams

[![Docker Stars](https://img.shields.io/docker/stars/jhamlin96/docker-nginx-rtmp.svg)](https://hub.docker.com/r/jhamlin96/docker-nginx-rtmp)
[![Docker Pulls](https://img.shields.io/docker/pulls/jhamlin96/docker-nginx-rtmp.svg)](https://hub.docker.com/r/jhamlin96/docker-nginx-rtmp/)
[![Docker Automated build](https://img.shields.io/docker/automated/jhamlin96/docker-nginx-rtmp.svg)](https://hub.docker.com/r/jhamlin96/docker-nginx-rtmp/builds/)
[![Build Status](https://travis-ci.org/jhamlin96/docker-nginx-rtmp.svg?branch=master)](https://travis-ci.org/jhamlin96/docker-nginx-rtmp)

## Prerequisites
* You will need to follow the os-specific instructions here to install the nvidia-docker runtime: https://github.com/NVIDIA/nvidia-container-runtime
* Most consumer cards are limited to 2 streams. Please do research about this limitation and possible solutions.

## Usage

### Server
* Pull docker image and run:
```
docker pull jhamlin96/docker-nginx-rtmp
docker run -it -p 1935:1935 -p 8080:80 --rm jhamlin96/docker-nginx-rtmp
```
or 

* Build and run container from source:
```
docker build -t nginx-rtmp-nvidia .
docker run -it -p 1935:1935 -p 8080:80 --rm nginx-rtmp-nvidia
```

* Stream live content to:
```
rtmp://<server ip>:1935/stream/$STREAM_NAME
```

### SSL 
To enable SSL, see [nginx.conf](nginx.conf) and uncomment the lines:
```
listen 443 ssl;
ssl_certificate     /opt/certs/example.com.crt;
ssl_certificate_key /opt/certs/example.com.key;
```

This will enable HTTPS using a self-signed certificate supplied in [/certs](/certs). If you wish to use HTTPS, it is **highly recommended** to obtain your own certificates and update the `ssl_certificate` and `ssl_certificate_key` paths.

I recommend using [Certbot](https://certbot.eff.org/docs/install.html) from [Let's Encrypt](https://letsencrypt.org).

### Environment Variables
This Docker image uses `envsubst` for environment variable substitution. You can define additional environment variables in `nginx.conf` as `${var}` and pass them in your `docker-compose` file or `docker` command.

### OBS Configuration
* Stream Type: `Custom Streaming Server`
* URL: `rtmp://localhost:1935/stream`
* Stream Key: `hello`

### Watch Stream
* In Safari, VLC or any HLS player, open:
```
http://<server ip>:8080/live/$STREAM_NAME.m3u8
```
* Example Playlist: `http://localhost:8080/live/hello.m3u8`
* [VideoJS Player](https://video-dev.github.io/hls.js/stable/demo/?src=http%3A%2F%2Flocalhost%3A8080%2Flive%2Fhello.m3u8)
* FFplay: `ffplay -fflags nobuffer rtmp://localhost:1935/stream/hello`

### FFmpeg Build
```
$ ffmpeg -buildconf
ffmpeg version 4.2.2 Copyright (c) 2000-2019 the FFmpeg developers
  built with gcc 7 (Ubuntu 7.4.0-1ubuntu1~18.04.1)
  configuration: --prefix=/usr/local --enable-version3 --enable-gpl --enable-nonfree --enable-small --enable-libmp3lame --enable-libx264 --enable-libx265 --enable-libvpx --enable-libtheora --enable-libvorbis --enable-libopus --enable-libfdk-aac --enable-libass --enable-libwebp --enable-postproc --enable-avresample --enable-libfreetype --enable-openssl --disable-debug --disable-doc --disable-ffplay --extra-libs='-lpthread -lm' --enable-nvenc --enable-cuda --enable-cuvid --enable-libnpp --extra-cflags='-I/usr/local/include -I/usr/local/include/ffnvcodec -I/usr/local/cuda/include/' --extra-ldflags='-L/usr/local/lib -L/usr/local/cuda/lib64'
  libavutil      56. 31.100 / 56. 31.100
  libavcodec     58. 54.100 / 58. 54.100
  libavformat    58. 29.100 / 58. 29.100
  libavdevice    58.  8.100 / 58.  8.100
  libavfilter     7. 57.100 /  7. 57.100
  libavresample   4.  0.  0 /  4.  0.  0
  libswscale      5.  5.100 /  5.  5.100
  libswresample   3.  5.100 /  3.  5.100
  libpostproc    55.  5.100 / 55.  5.100

  configuration:
    --prefix=/usr/local
    --enable-version3
    --enable-gpl
    --enable-nonfree
    --enable-small
    --enable-libmp3lame
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libtheora
    --enable-libvorbis
    --enable-libopus
    --enable-libfdk-aac
    --enable-libass
    --enable-libwebp
    --enable-postproc
    --enable-avresample
    --enable-libfreetype
    --enable-openssl
    --disable-debug
    --disable-doc
    --disable-ffplay
    --extra-libs='-lpthread -lm'
    --enable-nvenc
    --enable-cuda
    --enable-cuvid
    --enable-libnpp
    --extra-cflags='-I/usr/local/include -I/usr/local/include/ffnvcodec -I/usr/local/cuda/include/'
    --extra-ldflags='-L/usr/local/lib -L/usr/local/cuda/lib64'
```

## Resources
* https://alpinelinux.org/
* http://nginx.org
* https://github.com/arut/nginx-rtmp-module
* https://www.ffmpeg.org
* https://obsproject.com
