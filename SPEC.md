# CON Specification document draft

Not stable yet - work in progress

## Types

The format is designed to be as simple and as easy to parse as possible, while keeping a good level of readability.

All characters are UTF-8 encoded

### Delimiters

Delimiters are used in hashes to seprate keys and values, and arrays to separate elements.

At least one of this character is required. They can be chained, any combination is valid:
- ` `
- `\n`
- `\r`
- `\t`

### Key

A key is separated by its value with a delimiter

`str "value"`

This characters need to be escaped, in addition to delimiters:
- `\b`
- `\f`
- `\`
- `[`
- `]`
- `{`
- `}`

### Values

#### String

Strings are enclosed with two quotes

`"value"`

This characters need to be escaped, in addition to delimiters:
- `\b`
- `\f`
- `\`
- `"`

#### Integer

Integers are signed and 64-bit by default

```
int 1
neg -2
```

#### Float

Floats are signed and 64-bit by default

```
float 1.1
float -0.3
```

#### Bool

A boolean value can either take `true` or `false`

`enabled true`

#### Nil

`nil` represents the absence of value

`key nil`

#### Array

Arrays consists of elements separated by a delimiter, and enclosed by brackets.

Arrays of hashes don't require a delimiter.

```
array [
  "a"
  1
]
```

condensed:

`array[{a "b"}{c "d"}]`

#### Hash

Hashes consists of key/value pairs separated by a delimiter, and enclosed by curly brackets.

Curly braces aren't needed at the start/end of a document.

```
hash {
  key "value"
  other "val"
}
```

condensed:

`hash{key "value" other "val"}` or `{hash{key "value" other "val"}}`
