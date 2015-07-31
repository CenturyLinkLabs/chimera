FROM ubuntu:15.04

ENV COMPOSE_VERSION 1.3.3

RUN apt-get update -q \
    && apt-get install -y -q curl ca-certificates \
    && curl -L https://github.com/docker/compose/releases/download/1.3.3/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

ENV SERVER_PORT 5001
EXPOSE 5001 5001
ADD hydrago /
CMD ["hydrago"]
