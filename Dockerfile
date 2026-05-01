FROM ubuntu:latest AS openssl_builder
ENV DEBIAN_FRONTEND=noninteractive
ENV LS_COLORS="di=01;36"
ARG OPENSSL_PREFIX=/usr/local/openssl
WORKDIR /app

RUN apt update \
 && apt install -y --no-install-recommends \
    build-essential git ca-certificates make binutils \
    autoconf automake autotools-dev libtool pkg-config \
 && git clone --depth 1 https://github.com/openssl/openssl \
 && cd openssl \
 && ./config --prefix=$OPENSSL_PREFIX \
 && make -j$(grep -c processor /proc/cpuinfo) \
 && make install_sw install_ssldirs


FROM ubuntu:latest AS ngtcp2_builder
ENV DEBIAN_FRONTEND=noninteractive
ENV LS_COLORS="di=01;36"
ARG OPENSSL_PREFIX=/usr/local/openssl
ARG NGTCP2_PREFIX=/usr/local/ngtcp2
WORKDIR /app

COPY --from=openssl_builder /usr/local/openssl/ /usr/local/openssl/

RUN apt update \
 && apt install -y --no-install-recommends \
    build-essential git ca-certificates \
    autoconf automake autotools-dev libtool pkg-config \
 && git clone --depth 1 https://github.com/ngtcp2/ngtcp2 \
 && cd ngtcp2 \
 && autoreconf -fi \
 && PKG_CONFIG_PATH=$OPENSSL_PREFIX/lib64/pkgconfig \
    ./configure \
      --prefix=$NGTCP2_PREFIX \
      --with-openssl \
      --enable-lib-only \
 && make -j$(grep -c processor /proc/cpuinfo) \
 && make install


FROM ubuntu:latest AS curl_builder
ENV DEBIAN_FRONTEND=noninteractive
ENV LS_COLORS="di=01;36"
ARG OPENSSL_PREFIX=/usr/local/openssl
ARG NGTCP2_PREFIX=/usr/local/ngtcp2
ARG CURL3_PREFIX=/usr/local/curl3
WORKDIR /app

COPY --from=openssl_builder /usr/local/openssl/ /usr/local/openssl/
COPY --from=ngtcp2_builder /usr/local/ngtcp2/ /usr/local/ngtcp2/

RUN apt update \
 && apt install -y --no-install-recommends \
    build-essential git ca-certificates \
    autoconf automake autotools-dev libtool pkg-config \
    libbrotli-dev zlib1g-dev \
    libnghttp2-dev libnghttp3-dev \
    libpsl-dev libcunit1-dev \
    libssh2-1-dev \
 && git clone https://github.com/curl/curl \
 && cd curl \
 && autoreconf -fi \
 && PKG_CONFIG_PATH=$OPENSSL_PREFIX/lib64/pkgconfig:$NGTCP2_PREFIX/lib/pkgconfig \
    ./configure \
      --prefix=$CURL3_PREFIX \
      --with-openssl=$OPENSSL_PREFIX \
      --with-ngtcp2=$NGTCP2_PREFIX \
      --with-nghttp3 \
      --with-nghttp2 \
      --with-brotli \
      --with-zlib \
      --with-libssh2 \
      --enable-http3 \
      --enable-hsts \
      --enable-alt-svc \
      --enable-http-auth \
      --enable-unix-sockets \
      --enable-verbose \
      --enable-http \
      --enable-optimize \
      --enable-get-easy-options \
      --enable-ftp \
      --disable-ldap \
      --disable-rtsp \
      --disable-dict \
      --disable-telnet \
      --disable-tftp \
      --disable-pop3 \
      --disable-imap \
      --disable-smb \
      --disable-smtp \
      --disable-mqtt \
      --disable-gopher \
 && make -j$(grep -c processor /proc/cpuinfo) \
 && make install


FROM ubuntu:latest AS executor
ENV DEBIAN_FRONTEND=noninteractive
ENV LS_COLORS="di=01;36"
ARG OPENSSL_PREFIX=/usr/local/openssl
ARG NGTCP2_PREFIX=/usr/local/ngtcp2
ARG CURL3_PREFIX=/usr/local/curl3
WORKDIR /app

COPY --from=openssl_builder /usr/local/openssl/ /usr/local/openssl/
COPY --from=ngtcp2_builder /usr/local/ngtcp2/ /usr/local/ngtcp2/
COPY --from=curl_builder /usr/local/curl3/ /usr/local/curl3/

RUN apt update \
 && apt install -y --no-install-recommends \
    ca-certificates \
    libbrotli1 \
    libnghttp2-14 \
    libnghttp3-3 \
    libpsl5t64 \
    libssh2-1 \
 && echo "$OPENSSL_PREFIX/lib64" >> /etc/ld.so.conf.d/openssl.conf \
 && echo "$NGTCP2_PREFIX/lib" >> /etc/ld.so.conf.d/ngtcp2.conf \
 && echo "$CURL3_PREFIX/lib" >> /etc/ld.so.conf.d/curl3.conf \
 && ldconfig -v

ENTRYPOINT ["/usr/local/curl3/bin/curl"]
