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
 CON.parse minified 403.83k (  2.48µs) (± 4.67%)  1937 B/op        fastest
   CON.parse pretty 383.93k (   2.6µs) (± 3.35%)  1936 B/op   1.05× slower
JSON.parse minified 322.33k (   3.1µs) (± 3.63%)  2129 B/op   1.25× slower
  JSON.parse pretty  277.7k (   3.6µs) (± 3.82%)  2129 B/op   1.45× slower
```

```
        #to_con 896.16k (  1.12µs) (± 5.23%)  321 B/op        fastest
 #to_pretty_con  865.9k (  1.15µs) (± 1.93%)  321 B/op   1.03× slower
       #to_json 644.32k (  1.55µs) (± 2.49%)  578 B/op   1.39× slower
#to_pretty_json 515.68k (  1.94µs) (± 2.28%)  849 B/op   1.74× slower
```

## License

Copyright (c) 2018-2019 Julien Reichardt - ISC License
