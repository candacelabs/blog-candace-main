# blog

This tracks hugo-based sites, like the [blog](https://blog.candace.cloud) that are hosted on [candaceserver](https://candace.cloud). 

Fully containerized and plug-and-playable into any docker compose setup. 

## Example

```yaml

include:
  - docker-compose.blog.yaml

services:
  ...

```

## Usage

1. Fork it or use this
2. `cd` to the directory your main docker compose lives
3. Run 

```bash

git add submodule https://github.com/candacelabs/blog.git blog

```
or if you've forked it, replace the URL with your fork
5. Run `cp blog/docker-compose.blog.example.yaml docker-compose.blog.yaml`
6. Change network name as needed -- change ports if already using 1313
7. Add 
```yaml
include:
  - docker-compose.blog.yaml
```
to your docker compose file.

8. Run `docker compose up blog -d` to start your container




