## datascript.js

A JavaScript binding for [DataScript](http://datascript.sourceforge.net),
a declarative language for implementing binary data formats.

Initially I will focus on decoders, but I'd like to be able to use the same
language for encoding, too.

An example DataScript specification:

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
};

ElfSection(Elf32_File.Elf32_SectionHeader h) {
Elf32_File:: h.sh_offset:
  union {
    { } null : h.sh_type == SHT_NULL;
    StringTable(h) strtab : h.sh_type == SHT_STRTAB;
    SymbolTable(h) symtab : h.sh_type == SHT_SYMTAB;
    SymbolTable(h) dynsym : h.sh_type == SHT_DYNSYM;
    RelocationTable(h) rel : h.sh_type == SHT_REL;
    // ...
  } section;
};

SymbolTable(Elf32_File.Elf32_SectionHeader h) {
  Elf32_Sym {
    uint32 st_name;
    uint32 st_value;
    uint32 st_size;
    uint8  st_info;
    uint8  st_other;
    uint16 st_shndx;
  } entry[h.sh_size / sizeof Elf32_Sym];
};
```

After compiling the above specification to a JavaScript module, using it
looks like this:

```javascript
var Elf = require('elf');

var file = new Elf(buffer, 0);
console.log("0x" + file.e_ident.magic.toString(16)); // 0x7f454c46
```


## Status

**Nothing works yet.**

## Read more

For more about the design of DataScript, you can read the original paper:

Back, Godmar. [DataScript--a Specification and Scripting Language for Binary Data](http://people.cs.vt.edu/~gback/papers/gback-datascript-gpce2002.pdf). *Generative Programming and Component Engineering (GPCE)*, 2002.

## License

MIT
