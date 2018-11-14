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

## License

Copyright (c) 2018 Julien Reichardt - ISC License
