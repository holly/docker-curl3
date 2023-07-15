FROM ubuntu:latest AS quiche_builder
ENV DEBIAN_FRONTEND noninteractive
ENV LS_COLORS di=01;36
WORKDIR /app
RUN --mount=type=cache,target=/var/lib/apt/lists --mount=type=cache,target=/var/cache/apt/archives \
 apt update \
 && apt install -y --no-install-recommends build-essential git cargo ca-certificates cmake \
 && echo ">>> install quiche" \
 && git clone --recursive https://github.com/cloudflare/quiche \
 && cd quiche \
 && cargo build --package quiche --release --features ffi,pkg-config-meta,qlog \
 && mkdir quiche/deps/boringssl/src/lib \
 && ln -vnf $(find target/release -name libcrypto.a -o -name libssl.a) quiche/deps/boringssl/src/lib/ \
 && cd ../ 

FROM ubuntu:latest AS curl_builder
ENV DEBIAN_FRONTEND noninteractive
ENV LS_COLORS di=01;36
WORKDIR /app
COPY --from=quiche_builder /app/quiche /app/quiche
RUN --mount=type=cache,target=/var/lib/apt/lists --mount=type=cache,target=/var/cache/apt/archives \
 apt update \
 && apt install -y --no-install-recommends build-essential git autoconf libtool pkg-config libbrotli-dev libbrotli1 ca-certificates automake libcunit1-dev zlib1g-dev libnghttp2-dev \
 && echo ">>> install curl3" \
 && git clone https://github.com/curl/curl \
 && cd curl \
 && autoreconf -fi \
 && ./configure LDFLAGS="-Wl,-rpath,$PWD/../quiche/target/release" --with-openssl=$PWD/../quiche/quiche/deps/boringssl/src --with-quiche=$PWD/../quiche/target/release  --with-brotli --with-zlib --with-nghttp2 --enable-hsts --enable-alt-svc --enable-http-auth --enable-unix-sockets --enable-verbose --enable-http --enable-optimize --enable-get-easy-options --disable-ftp --disable-ldap --disable-rtsp --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smb --disable-smtp --disable-mqtt   --disable-gopher \
 && make \
 && make install \
 && cd ../

FROM ubuntu:latest AS executor
ENV DEBIAN_FRONTEND noninteractive
ENV LS_COLORS di=01;36
ENV LD_LIBRARY_PATH /usr/local/lib:/app/quiche/target/release
WORKDIR /app
COPY --from=quiche_builder /app/quiche /app/quiche
COPY --from=curl_builder /usr/local /usr/local
RUN --mount=type=cache,target=/var/lib/apt/lists --mount=type=cache,target=/var/cache/apt/archives \
  apt update \
  && apt install -y --no-install-recommends libbrotli1  ca-certificates libnghttp2-14 
ENTRYPOINT ["/usr/local/bin/curl"]
