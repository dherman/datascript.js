## datascript.js

A JavaScript binding for [DataScript](http://datascript.sourceforge.net),
a declarative language for implementing binary data formats.

Initially I will focus on decoders, but I'd like to be able to use the same
language for encoding, too.

An example:

```
Elf32_File {
  Elf_Identification {
    uint32 magic = 0x7f454c46;
    // ...
  } e_ident;

  // ...

  uint32 e_shoff;
  uint32 e_flags;
  uint16 e_ehsize;
  uint16 e_phentsize;
  uint16 e_phnum;
  uint16 e_shentsize;
  uint16 e_shnum;
  uint16 e_shtrndx;

  // ...

e_shoff:
  Elf32_SectionHeader {
    uint32 sh_name;
    uint32 sh_type;
    uint32 sh_flags;
    uint32 sh_addr;
    uint32 sh_offset;
    uint32 sh_size;
    uint32 sh_link;
    uint32 sh_info;
    uint32 sh_addralign;
    uint32 sh_entsize;
  } hdrs[e_shnum];

  ElfSection(hdrs[s.index]) s[e_shnum];
}
```

## Status

**Nothing works yet.**

## Read more

For more about the design of DataScript, you can read the original paper:

Back, Godmar. [DataScript--a Specification and Scripting Language for Binary Data](http://people.cs.vt.edu/~gback/papers/gback-datascript-gpce2002.pdf). *Generative Programming and Component Engineering (GPCE)*, 2002.

## License

MIT
