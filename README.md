```
Usage:
  bin/simple-debit [-o|--output=<Str>] [--base-uri=<Str>] [--retry[=UInt]] [--retry-on-client-error] [-v|--verbose]
  bin/simple-debit [-o|--output=<Str>] [--base-uri=<Str>] [--retry[=UInt]] [--retry-on-client-error] [-v|--verbose] [<ids> ...]

    -o|--output=<Str>          output file name
    --base-uri=<Str>           base uri used to fetch client list and each client
    --retry[=UInt]             max number of retries
    --retry-on-client-error    it defaults to only retry on server errors (5xx) if defined, it will retry on client errors (4xx) as well
    -v|--verbose               prints what its going to do
    [<ids> ...]                list of client ids to be used
```

## Test:

```
mi6 test
```

## Install:

```
zef install .
```
