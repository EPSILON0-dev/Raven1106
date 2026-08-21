FROM debian:12

COPY ./scripts/setup_docker_environment.sh /tmp/setup.sh

RUN sh /tmp/setup.sh && rm /tmp/setup.sh

VOLUME /work
WORKDIR /work
