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
 CON.parse minified 669.91k (  1.49µs) (± 1.74%)  1856 B/op   1.03× slower
   CON.parse pretty 601.45k (  1.66µs) (± 3.08%)  1856 B/op   1.15× slower
JSON.parse minified 689.32k (  1.45µs) (± 3.54%)  1698 B/op        fastest
  JSON.parse pretty 579.35k (  1.73µs) (± 2.01%)  1698 B/op   1.19× slower
```

```
 CON::Builder minified   1.71M ( 585.7ns) (± 4.46%)  176 B/op        fastest
   CON::Builder pretty   1.06M (947.45ns) (± 2.34%)  608 B/op   1.62× slower
JSON::Builder minified   1.15M ( 872.4ns) (± 5.67%)  576 B/op   1.49× slower
  JSON::Builder pretty 889.92k (  1.12µs) (± 1.79%)  849 B/op   1.92× slower
```

## License

Copyright (c) 2018 Julien Reichardt - ISC License
