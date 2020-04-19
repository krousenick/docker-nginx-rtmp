

# ffmpeg - http://ffmpeg.org/download.html
#
# From https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
#
# https://hub.docker.com/r/jrottenberg/ffmpeg/
#
#

FROM    nvidia/cuda:10.2-devel-ubuntu18.04 AS devel-base

ENV	    NVIDIA_DRIVER_CAPABILITIES compute,utility,video
WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 && \
        apt-get autoremove -y && \
        apt-get clean -y

FROM        nvidia/cuda:10.2-runtime-ubuntu18.04 AS runtime-base

ENV	    NVIDIA_DRIVER_CAPABILITIES compute,utility,video
WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 libxcb-shape0-dev gettext openssl curl rtmpdump lame libogg0 curl libass9 libvpx5 libvorbis0a libvorbisenc2 libwebp6 libwebpmux3 libwebpdemux2 libtheora0 libopusfile0 libfdk-aac1 libx264-152 libx265-146 && \
        apt-get autoremove -y && \
        apt-get clean -y


FROM  devel-base as build-ffmpeg

ENV     NVIDIA_HEADERS_VERSION=9.1.23.1
ENV	FFMPEG_VERSION=4.2.2
ARG 	PREFIX=/usr/local
ARG	MAKEFLAGS="-j4"
RUN     buildDeps="autoconf \
                    automake \
                    cmake \
                    curl \
                    bzip2 \
                    libexpat1-dev \
                    g++ \
                    gcc \
                    git \
                    gperf \
                    libtool \
                    make \
                    nasm \
                    perl \
                    pkg-config \
                    python \
                    libssl-dev \
                    yasm \
		    libmp3lame-dev \
		    libogg-dev \
		    libass-dev \
		    libvpx-dev \
		    libvorbis-dev \
		    libwebp-dev \
		    libtheora-dev \
		    libssl-dev \
	   	    libopus-dev \
		    librtmp-dev \
		    wget \
		    libx264-dev \
		    libx265-dev \
		    libfdk-aac-dev \
                    zlib1g-dev" && \
        apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ${buildDeps}

RUN \
	DIR=/tmp/nv-codec-headers && \
	git clone https://github.com/FFmpeg/nv-codec-headers ${DIR} && \
	cd ${DIR} && \
	git checkout n${NVIDIA_HEADERS_VERSION} && \
	make PREFIX="${PREFIX}" && \
	make install PREFIX="${PREFIX}" && \
        rm -rf ${DIR}

## ffmpeg https://ffmpeg.org/
RUN  \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        curl -sLO https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        tar -jx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.bz2 
RUN \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        ./configure \
	--prefix=${PREFIX} \
	--enable-version3 \
	--enable-gpl \
	--enable-nonfree \
	--enable-small \
	--enable-libmp3lame \
	--enable-libx264 \
	--enable-libx265 \
	--enable-libvpx \
	--enable-libtheora \
	--enable-libvorbis \
	--enable-libopus \
	--enable-libfdk-aac \
	--enable-libass \
	--enable-libwebp \
	--enable-postproc \
	--enable-avresample \
	--enable-libfreetype \
	--enable-openssl \
	--disable-debug \
	--disable-doc \
	--disable-ffplay \
	--extra-libs="-lpthread -lm" \
	--enable-nvenc \
        --enable-cuda \
        --enable-cuvid \
        --enable-libnpp \
        --extra-cflags="-I${PREFIX}/include -I${PREFIX}/include/ffnvcodec -I/usr/local/cuda/include/" \
        --extra-ldflags="-L${PREFIX}/lib -L/usr/local/cuda/lib64" && \
        make && \
        make install && \
        make distclean 

FROM devel-base as build-nginx 
# Versions of Nginx and nginx-rtmp-module to use
ENV NGINX_VERSION nginx-1.17.10
ENV NGINX_RTMP_MODULE_VERSION 1.2.1
ARG 	PREFIX=/usr/local
ARG	MAKEFLAGS="-j4"

# Install dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates openssl libssl-dev wget libpcre3 libpcre3-dev && \
    rm -rf /var/lib/apt/lists/*

# Get nginx source.
RUN cd /tmp && \
  wget https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
  tar zxf ${NGINX_VERSION}.tar.gz && \
  rm ${NGINX_VERSION}.tar.gz && \
  # PCRE version 8.42
  wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz && tar xzvf pcre-8.44.tar.gz && \
  rm pcre-8.44.tar.gz && \
  # zlib version 1.2.11
  wget https://www.zlib.net/zlib-1.2.11.tar.gz && tar xzvf zlib-1.2.11.tar.gz && \
  rm zlib-1.2.11.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget --no-check-certificate --auth-no-challenge https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_MODULE_VERSION}.tar.gz && rm v${NGINX_RTMP_MODULE_VERSION}.tar.gz

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/${NGINX_VERSION} && \
  ./configure \
  --prefix=/usr/local/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} \
  --conf-path=/etc/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-http_ssl_module \
  --with-debug \
  --with-pcre=../pcre-8.44 \
  --with-zlib=../zlib-1.2.11 \
  --with-cc-opt="-Wimplicit-fallthrough=0" && \
  cd /tmp/${NGINX_VERSION} && make && make install


FROM        runtime-base AS release
MAINTAINER  Jared Hamlin <jhamlin96@gmail.com>

COPY --from=build-ffmpeg /usr/local/ /usr/local/
COPY --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --from=build-nginx /etc/nginx /etc/nginx

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/sbin"
ADD nginx.conf /etc/nginx/nginx.conf.template
RUN mkdir -p /opt/data && mkdir /www
ADD static /www/static

EXPOSE 1935
EXPOSE 80

CMD envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && \
  nginx

# Let's make sure the app built correctly
# Convenient to verify on https://hub.docker.com/r/jrottenberg/ffmpeg/builds/ console output



