FROM ubuntu:latest

ARG HUGO_VERSION=0.148.0

RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Download and install the specific Hugo .deb package
RUN curl -L "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_withdeploy_${HUGO_VERSION}_linux-amd64.deb" \
    -o hugo.deb \
    && dpkg -i hugo.deb \
    && rm hugo.deb

# Hugo tries to create a lock file when building but since we change the user
# we have to give the Hugo server process user permission to write to the 
# /srv directory. This way any stateful changes run INSIDE a container as 
# WELL as without user permissions making accepting user input extremely safe 
# here.
RUN chown -R 1000:1000 /srv

# Use existing user with ID 1000 (usually 'ubuntu' user)
USER 1000:1000
WORKDIR /srv

ENTRYPOINT ["hugo", "server", "--bind", "0.0.0.0", "-p", "1313", "-e", "production"]