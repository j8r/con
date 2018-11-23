# CON

Cretin Object Notation - a simple, fast and readable JSON-compatible serialization format

**WORK IN PROGRESS** - the specifications aren't stable and will change

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
 CON.parse minified 636.54k (  1.57µs) (± 3.02%)  1936 B/op        fastest
   CON.parse pretty 572.87k (  1.75µs) (± 1.32%)  1936 B/op   1.11× slower
JSON.parse minified 562.57k (  1.78µs) (± 1.80%)  2128 B/op   1.13× slower
  JSON.parse pretty 477.41k (  2.09µs) (± 3.85%)  2128 B/op   1.33× slower
```

```
 CON::Builder minified   1.24M (807.52ns) (± 2.04%)   320 B/op        fastest
   CON::Builder pretty 674.25k (  1.48µs) (±19.03%)  1057 B/op   1.84× slower
JSON::Builder minified 853.06k (  1.17µs) (± 7.70%)   576 B/op   1.45× slower
  JSON::Builder pretty 703.44k (  1.42µs) (± 6.03%)   848 B/op   1.76× slower

```

## License

Copyright (c) 2018 Julien Reichardt - ISC License
