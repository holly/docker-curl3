FROM ubuntu:latest AS builder
ENV DEBIAN_FRONTEND noninteractive
ENV LS_COLORS di=01;36
#COPY app/ /app
WORKDIR /app
RUN --mount=type=cache,target=/var/lib/apt/lists --mount=type=cache,target=/var/cache/apt/archives \
 apt update \
 && apt install -y --no-install-recommends build-essential git autoconf libtool pkg-config cmake libbrotli-dev libbrotli1 ca-certificates automake libcunit1-dev zlib1g-dev \
 && echo ">>> install openssl+quicltls" \
 && git clone --depth 1 -b openssl-3.0.9+quic https://github.com/quictls/openssl  \
 && cd openssl \
 && ./config enable-tls1_3 --prefix=/usr/local/ssl \
 && make -j$(nproc)\
 && make install \
 && cd ../ \
 && echo ">>> install nghttp3" \
 && git clone https://github.com/ngtcp2/nghttp3 \
 && cd nghttp3 \
 && autoreconf -fi \
 && ./configure --prefix=/usr/local/nghttp3 --enable-lib-only \
 && make \
 && make install \
 && cd ../  \
 && echo ">>> install ngtcp2" \
 && git clone  https://github.com/ngtcp2/ngtcp2 \
 && cd ngtcp2 \
 && git checkout v0.16.0 \
 && autoreconf -fi \
 && ./configure PKG_CONFIG_PATH=/usr/local/ssl/lib64/pkgconfig:/usr/local/nghttp3/lib/pkgconfig LDFLAGS="-Wl,-rpath,/usr/local/ssl/lib64" --prefix=/usr/local/ngtcp2 --enable-lib-only \
 && make \
 && make install \
 #&& cd /usr/local/ngtcp2/lib/pkgconfig \
 #&& ln -sf libngtcp2_crypto_quictls.pc libngtcp2_crypto_openssl.pc \
 && cd ../ \
 && echo ">>> install nghttp2" \
 && git clone https://github.com/nghttp2/nghttp2.git \
 && cd nghttp2 \
 && git checkout v1.53.0 \
 && autoreconf -fi \
 && automake \
 && autoconf \
 && ./configure PKG_CONFIG_PATH=/usr/local/ssl/lib64/pkgconfig:/usr/local/ngtcp2/lib/pkgconfig:/usr/local/nghttp3/lib/pkgconfig --prefix=/usr/local/nghttp2 --with-openssl=/usr/local/ssl  --with-libngtcp2=/usr/local/ngtcp2   --with-libnghttp3=/usr/local/nghttp3 --enable-http3 \
 && make \
 && make install \
 && cd ../ \
 && echo ">>> install curl3" \
 && git clone https://github.com/curl/curl \
 && cd curl \
 && autoreconf -fi \
 && LDLAGS="-Wl,-rpath,/usr/local/ssl/lib64" ./configure --with-openssl=/usr/local/ssl --with-nghttp2=/usr/local/nghttp2 --with-nghttp3=/usr/local/nghttp3 --with-ngtcp2=/usr/local/ngtcp2 --with-brotli --with-zlib --enable-hsts --enable-alt-svc --enable-http-auth --enable-unix-sockets --enable-verbose --enable-http --enable-optimize --enable-get-easy-options --disable-ftp --disable-ldap --disable-rtsp --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smb --disable-smtp --disable-mqtt   --disable-gopher \
 && make \
 && make install \
 && cd ../ 
#CMD [ "/bin/bash" ]

FROM ubuntu:latest AS executor
ENV DEBIAN_FRONTEND noninteractive
ENV LS_COLORS di=01;36
WORKDIR /app
COPY app/curl3.conf /etc/ld.so.conf.d/curl3.conf 
COPY --from=builder /usr/local /usr/local
RUN --mount=type=cache,target=/var/lib/apt/lists --mount=type=cache,target=/var/cache/apt/archives \
  apt update \
  && apt install -y --no-install-recommends libbrotli1 ca-certificates  \
  && ldconfig -v
ENTRYPOINT [ "/usr/local/bin/curl" ]
