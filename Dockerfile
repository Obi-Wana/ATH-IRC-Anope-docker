FROM alpine:3.23

LABEL org.opencontainers.image.authors="Anope Team <team@anope.org>"

ARG VERSION=2.1
ARG RUN_DEPENDENCIES="gnutls gnutls-utils mariadb-client mariadb-connector-c sqlite-libs"
ARG BUILD_DEPENDENCIES="gnutls-dev mariadb-dev sqlite-dev"
ARG EXTRA_MODULES="mysql sqlite ssl_gnutls ssl_openssl"
ARG GITHUB_TOKEN

# Setup private repo
RUN apk add --no-cache git
RUN mkdir -p /src
RUN git clone --depth 1 https://obi-wana:${GITHUB_TOKEN}@github.com/Obi-Wana/ATH-IRC-Anope /src/anope

RUN apk add --no-cache --virtual .build-utils gcc g++ ninja git cmake $BUILD_DEPENDENCIES && \
    apk add --no-cache --virtual .dependencies libgcc libstdc++ $RUN_DEPENDENCIES

# Create a user to run anope later
RUN adduser -u 10000 -h /anope/ -D -S anope

RUN cd /src/anope && \
    # Add and overwrite modules
    for module in $EXTRA_MODULES; do ln -s /src/anope/modules/extra/$module.cpp modules; done

RUN mkdir /src/anope/build
RUN cd /src/anope/build && \
    cmake -DINSTDIR=/anope/ -DDEFUMASK=077 -DCMAKE_BUILD_TYPE=RELEASE -GNinja .. && \
    # Run build multi-threaded
    ninja install && \
    # Uninstall all unnecessary tools after build process
    apk del .build-utils && \
    rm -rf /src && \
    # Provide a data location
    mkdir -p /data && \
    touch /data/anope.db && \
    ln -s /data/anope.db /anope/data/anope.db && \
    # Make sure everything is owned by anope
    chown -R anope /anope/ && \
    chown -R anope /data/

COPY ./conf/ /anope/conf/

RUN chown -R anope /anope/conf/

WORKDIR /anope/

VOLUME /data/

USER anope

CMD ["/anope/bin/anope", "-nofork"]

