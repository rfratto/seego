# seego

`seego` is a multiarch Docker build environment image that wraps around `go` to
enable easier crosscompilation of packages that require `CGO_ENABLED=1`.

## Usage

```bash
docker run --rm -v $(pwd):$(pwd) -w $(pwd) rfratto/seego <arguments to go>
```

To compile for different platforms, specify values for `GOOS`, `GOARCH` and
`GOARM` (if needed) as appropriate.

For example:

```bash
docker run -e GOOS=darwin -e GOARCH=amd64 --rm -v $(pwd):$(pwd) -w $(pwd) rfratto/seego build github.com/grafana/agent/cmd/agent
```

## Supported platforms

|          | linux | darwin | freebsd | windows |
| -------- | ----- | ------ | ------- | ------- |
| amd64    |     x |      x |       x |       x |
| 386      |     x |        |       x |       x |
| armv5    |     x |        |         |         |
| armv6    |     x |        |         |         |
| armv7    |     x |        |         |         |
| arm64    |     x |        |         |         |
| ppc64    |     x |        |         |         |
| ppc64le  |     x |        |         |         |
| mips     |     x |        |         |         |
| mipsle   |     x |        |         |         |
| mips64   |     x |        |         |         |
| mips64le |     x |        |         |         |
| s390x    |     x |        |         |         |

## Credits

This project is inspired by [crossbuild](https://github.com/multiarch/crossbuild)
and [Prometheus' golang-builder](https://github.com/prometheus/golang-builder).

FreeBSD crosscompilers are extracted from FreeBSD 11.3.
