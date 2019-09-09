# CON

[![Build Status](https://cloud.drone.io/api/badges/j8r/con/status.svg)](https://cloud.drone.io/j8r/con)
[![ISC](https://img.shields.io/badge/License-ISC-blue.svg?style=flat-square)](https://en.wikipedia.org/wiki/ISC_license)

Cretin Object Notation - a simple, fast and readable JSON-compatible serialization format

The specifications is mostly stable, but can be subject to minor changes.

## Example

```hcl
key "string"
pi 3.14
hash {
  enable true
  nothing nil
}
ports [
  22
  1234
  8888
]
```

## Features

- Backward compatible with JSON
- Easy to read, fast to parse
- Simple specifications

## Documentation

https://j8r.github.io/con

## Specifications

Specification document: [SPEC.md](SPEC.md)

## Usage

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  con:
    github: j8r/con
```


This object is a convenient container.

A `CON::Any` can be converted back to either a CON or JSON serialized `String`


```crystal
require "con"

con_any = CON.parse con_data
con_any.to_con

require "json"
con_any.to_json
```

`CON::PullParser` can be used to parse more efficiently, if the mapping is known in advance.

See [spec](spec) for more test examples.

## Benchmarks

There are benchmarks comparing `CON` and the stdlib's `JSON` implementation

`crystal run --release benchmark/*`

Some results:

```
 CON.parse minified 527.25k (  1.90µs) (±13.77%)  1.88kB/op        fastest
   CON.parse pretty 501.42k (  1.99µs) (±15.08%)  1.88kB/op   1.05× slower
JSON.parse minified 487.52k (  2.05µs) (± 9.05%)  2.08kB/op   1.08× slower
  JSON.parse pretty 409.80k (  2.44µs) (± 9.13%)  2.08kB/op   1.29× slower
```

```
        #to_con   1.17M (852.99ns) (± 3.51%)  320B/op        fastest
 #to_pretty_con   1.10M (908.96ns) (± 5.76%)  320B/op   1.07× slower
       #to_json 742.97k (  1.35µs) (±14.52%)  576B/op   1.58× slower
#to_pretty_json 612.21k (  1.63µs) (±13.04%)  848B/op   1.91× slower
```

## License

Copyright (c) 2018-2019 Julien Reichardt - ISC License
