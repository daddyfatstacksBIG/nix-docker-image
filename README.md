# Nix Docker Image

To get the exact right dependencies inside a Docker image we can use Nix. This
allows us to reuse existing Nix expression so that we get better control of the
software we deploy.

## Building an image

To build and add the image to `docker`:

```sh
docker load < $(nix-build --no-out-link)
```

## Running nix inside a container

To speed up build times we share the `/nix` directory between containers using
a volume (`nix-db`) which won't be destroyed between container invocations.

`/nix/` contains the `/nix/store` where all installed packages reside.

Use `docker volume prune` if you are done using the `makerdao/nix` image.

Run a nix build e.g. `tdds`:

```sh
docker run --rm \
  -v nix-db:/nix --tmpfs /tmp \
  makerdao/nix \
  nix-build --verbose \
    https://github.com/makerdao/testchain-dss-deployment-scripts/tarball/nixify-poc \
    -A tdds
```

Drop into an interactive shell:

```sh
docker run --rm -ti \
  -v nix-db:/nix --tmpfs /tmp \
  makerdao/nix \
  bash
```

## Run one command

Set your `seth` environment variables and run:

```sh
docker run --rm \
  -v nix-db:/nix --tmpfs /tmp \
  --env-file <(env | grep ETH_) \
  makerdao/nix \
  nix run \
    -f https://github.com/makerdao/testchain-dss-deployment-scripts/tarball/nixify-poc tdds \
    -c step-1-deploy
```

Use a local clone of `tdds`:

```sh
docker run --rm \
  -v nix-db:/nix --tmpfs /tmp \
  -v ~/src/maker/testchain-dss-deployment-scripts:/tdds \
  --env-file <(env | grep ETH_) \
  makerdao/nix \
  nix run \
    -f /tdds tdds \
    -c step-1-deploy
```
