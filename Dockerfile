# syntax=docker/dockerfile:1

ARG FUTU_OPEND_RS_VER=1.4.73
#ARG FUTU_OPEND_RS_VER=latest

FROM debian:bookworm-slim AS build

ARG TARGETARCH
ARG FUTU_OPEND_RS_VER

RUN apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates curl tar && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

COPY --chmod=0755 script/download-futu-opend-rs.sh /usr/local/bin/download-futu-opend-rs.sh

RUN /usr/local/bin/download-futu-opend-rs.sh

FROM debian:trixie-slim AS final

ARG FUTU_OPEND_RS_VER=1.4.73
#ARG FUTU_OPEND_RS_VER=latest

RUN apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates curl libdbus-1-3 && \
    rm -rf /var/lib/apt/lists/* && \
    install -d -m 0755 /etc/futu-opend /var/lib/futu /var/log/futu

COPY --from=build /tmp/futu-opend-rs-${FUTU_OPEND_RS_VER}/futu-opend /usr/local/bin/futu-opend
COPY --from=build /tmp/futu-opend-rs-${FUTU_OPEND_RS_VER}/futu-mcp /usr/local/bin/futu-mcp
COPY --from=build /tmp/futu-opend-rs-${FUTU_OPEND_RS_VER}/futucli /usr/local/bin/futucli
COPY --chmod=0755 script/entrypoint-opend.sh /usr/local/bin/entrypoint-opend.sh
COPY --chmod=0755 script/entrypoint-mcp.sh /usr/local/bin/entrypoint-mcp.sh
COPY --chmod=0755 script/entrypoint-all.sh /usr/local/bin/entrypoint-all.sh

RUN chmod 0755 /usr/local/bin/futu-opend /usr/local/bin/futu-mcp /usr/local/bin/futucli

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/entrypoint-all.sh"]
CMD ["both"]
