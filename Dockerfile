ARG ALPINE_VERSION=3.20
ARG GO_VERSION=1.23.0

FROM docker.io/golang:${GO_VERSION}-alpine as build

RUN apk add --no-cache make tar gzip

ADD https://github.com/coredns/coredns/archive/refs/tags/v1.11.3.tar.gz /opt/coredns.tar.gz

RUN tar xzf /opt/coredns.tar.gz -C /opt/ && \
    mv /opt/coredns-1.11.3 /opt/coredns

WORKDIR /opt/coredns

# Build coredns before adding the plugin to enable faster incremental builds.
RUN go generate
RUN make

# Add the blocker plugin before the cache plugin.
RUN sed -i '/cache:cache/i blocker:blocker' plugin.cfg

ADD . ./plugin/blocker

RUN go generate
RUN make

FROM scratch

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /opt/coredns/coredns /coredns

EXPOSE 53 53/udp

ENTRYPOINT ["/coredns"]