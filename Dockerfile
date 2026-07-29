FROM ubuntu:24.04

ARG HUGO_VERSION=0.164.0
ARG HUGO_SHA256=87bf5db4230dc9c4e41bf4d77ac9d06220265ce21f6e3126886edd32f21a41dc

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Pin and verify the Hugo release package before installing it.
RUN curl --fail --location --show-error \
    "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_withdeploy_${HUGO_VERSION}_linux-amd64.deb" \
    -o hugo.deb \
    && echo "${HUGO_SHA256}  hugo.deb" | sha256sum --check --strict \
    && dpkg -i hugo.deb \
    && rm hugo.deb

COPY --chown=1000:1000 ["themes/candace", "/themes/candace"]

RUN mkdir -p /srv && chown -R 1000:1000 /srv

USER 1000:1000
WORKDIR /srv

EXPOSE 1313

ENTRYPOINT ["hugo"]
CMD ["server", "--bind", "0.0.0.0", "--port", "1313", "--environment", "production", "--disableLiveReload", "--noBuildLock"]
