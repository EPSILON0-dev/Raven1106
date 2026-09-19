FROM debian:12

COPY ./scripts/build.sh /tmp/setup.sh

RUN sh /tmp/setup.sh setup && rm /tmp/setup.sh

USER builder
VOLUME /work
WORKDIR /work
