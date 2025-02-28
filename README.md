# cmp-pandoc-references

Based on https://github.com/jc-doyle/cmp-pandoc-referencesc.
A source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) or [blink.cmp](https://github.com/saghen/blink.cmp).
Provides completion for bibliography, reference and cross-ref items.

## Demo

![cmp-pandoc-references](https://user-images.githubusercontent.com/59124867/134782887-33872ae0-a23e-4f5b-99cd-74c3b0e6f497.gif)

## Installation

Install with your favorite package manager from:

```lua
"jmbuhr/cmp-pandoc-references"
```

## nvim-cmp

``` lua
require('cmp').setup {
  sources = {
    { name = 'pandoc_references' }
  }
}
```

## blink.cmp

```lua
-- ...
    references = {
        name = "pandoc_references",
        module = "cmp-pandoc-references.blink",
    },
-- ...
```

## Explanation & Limitations

This source parses and validates the `bibliography: <your/bib/location.bib>` YAML metadata field, to determine the destination of the file (see [Pandoc](https://pandoc.org/MANUAL.html#specifying-bibliographic-data)).
If it is not included (or you specify it through a command-line argument), no bibliography completion items will be found.

