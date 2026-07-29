FROM caddy:2.11.4-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648

ARG VCS_REF

LABEL org.opencontainers.image.source="https://github.com/candacelabs/blog-candace-main"
LABEL org.opencontainers.image.revision="${VCS_REF}"

RUN setcap -r /usr/bin/caddy

COPY --chown=65534:65534 . /srv

USER 65534:65534

EXPOSE 8080

HEALTHCHECK --interval=5s --timeout=3s --start-period=3s --retries=12 \
  CMD wget --quiet --output-document=/dev/null http://127.0.0.1:8080/ || exit 1

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["file-server", "--root", "/srv", "--listen", ":8080"]
