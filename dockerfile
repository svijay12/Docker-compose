FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    cmake \
    build-essential \
    pkg-config \
    libconfuse-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

ADD https://github.com/roehling/postsrsd/archive/refs/tags/2.4.1.tar.gz /tmp/postsrsd.tar.gz

RUN tar -xzf /tmp/postsrsd.tar.gz -C /build --strip-components=1 \
    && cmake -S /build -B /build/build \
       -DCMAKE_BUILD_TYPE=Release \
       -DCMAKE_INSTALL_PREFIX=/usr/local \
       -DBUILD_TESTING=OFF \
       -DINSTALL_SYSTEMD_SERVICE=OFF \
       -DGENERATE_SRS_SECRET=OFF \
    && cmake --build /build/build --parallel \
    && cmake --install /build/build

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libconfuse2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/sbin/postsrsd /usr/local/sbin/postsrsd

RUN mkdir -p /etc/postsrsd /usr/local/var/lib/postsrsd

COPY postSRSd.conf /etc/postsrsd/postsrsd.conf

EXPOSE 10003

CMD ["/usr/local/sbin/postsrsd", "-C/etc/postsrsd/postsrsd.conf"]
