# noisd

Build the noisd binary and a noisd container.

## Getting started

To build noisd, run

```
$ cd full-node && ./build.sh
```

and test the resulting binary

```
$ ./wasmd/build/noisd version
0.28.0

$ ./wasmd/build/noisd query wasm libwasmvm-version
1.0.0
```

Please note that this binary relies on an rpath value specific to the Go build system. So it can only be used on the machine where it was built. When moving the build result to a different machine, the correct dynamic library needs to be found.

Have fun with noisd!

### Docker build

Create a local docker build

```
$ docker build --pull -t noislabs/nois:manual .
```

And test it

```
$ docker run -e EXEC_MODE=genesis noislabs/nois:manual
```

### Install binary directly on host and run it

go to local_dev

```
$ cd local_dev 
```

And execute setup.sh

```
$ ./setup.sh
```