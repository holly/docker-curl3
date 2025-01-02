FROM ubuntu:latest AS openssl_builder
ENV DEBIAN_FRONTEND=noninteractive
ENV LS_COLORS="di=01;36"
ARG OPENSSL_PREFIX=/usr/local/openssl
WORKDIR /app
#RUN --mount=type=cache,target=/var/lib/apt/lists --mount=type=cache,target=/var/cache/apt/archives \
RUN apt update \
 && apt install -y --no-install-recommends build-essential git ca-certificates make binutils autoconf automake autotools-dev libtool pkg-config \
 && git clone --depth 1 https://github.com/openssl/openssl \
 && cd openssl \
 && ./config --prefix=$OPENSSL_PREFIX \
 && make -j$(grep -c processor /proc/cpuinfo) \
 && make install_sw install_ssldirs \
 && cd ../ 

FROM ubuntu:latest AS curl_builder
ENV DEBIAN_FRONTEND=noninteractive
ENV LS_COLORS="di=01;36"
WORKDIR /app
ARG OPENSSL_PREFIX=/usr/local/openssl
ARG CURL3_PREFIX=/usr/local/curl3
COPY --from=openssl_builder /usr/local/openssl/ /usr/local/openssl/
#RUN --mount=type=cache,target=/var/lib/apt/lists --mount=type=cache,target=/var/cache/apt/archives \
RUN apt update \
  && apt install -y --no-install-recommends build-essential git autoconf libtool pkg-config libbrotli-dev libbrotli1 ca-certificates automake libcunit1-dev zlib1g-dev libnghttp2-dev libnghttp3-dev libpsl-dev \
  && git clone https://github.com/curl/curl  \
  && cd curl \
  && autoreconf -fi \
  && PKG_CONFIG_PATH=$OPENSSL_PREFIX/lib/pkgconfig ./configure --prefix=$CURL3_PREFIX --with-openssl=$OPENSSL_PREFIX --with-openssl-quic --with-brotli --with-zlib --with-nghttp2 --with-nghttp3 --enable-hsts --enable-alt-svc --enable-http-auth --enable-unix-sockets --enable-verbose --enable-http --enable-optimize --enable-get-easy-options --enable-ftp --disable-ldap --disable-rtsp --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smb --disable-smtp --disable-mqtt   --disable-gopher \
  && make -j$(grep -c processor /proc/cpuinfo) \
  && make install \
  && cd ../

FROM ubuntu:latest AS executor
ENV DEBIAN_FRONTEND=noninteractive
ENV LS_COLORS="di=01;36"
WORKDIR /app
ARG OPENSSL_PREFIX=/usr/local/openssl
ARG CURL3_PREFIX=/usr/local/curl3
COPY --from=openssl_builder /usr/local/openssl/ /usr/local/openssl/
COPY --from=curl_builder /usr/local/curl3/ /usr/local/curl3/
RUN --mount=type=cache,target=/var/lib/apt/lists --mount=type=cache,target=/var/cache/apt/archives \
  apt update \
  && apt install -y --no-install-recommends libbrotli1  ca-certificates libnghttp2-14  libnghttp3-3 libpsl5t64 \
  && echo "$OPENSSL_PREFIX/lib64" >>/etc/ld.so.conf.d/openssl.conf \
  && echo "$CURL3_PREFIX/lib" >>/etc/ld.so.conf.d/curl3.conf \
  && ldconfig -v
ENTRYPOINT ["/usr/local/curl3/bin/curl"]
