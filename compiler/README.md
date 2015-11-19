Usage (by nekketsuuu)

``` bash
$ make clean
$ ./to_cartelet
$ (make arcturu) # for @arcturu
$ make byte-code
```

You can use Tab to autocomplete :)

If you want to print some internal expression, use

``` bash
$ make debug [LEVEL=lstr]
```

*lstr* is the level of internal expression (default: Asm), which is one of the below:

> Parser, Typing, KNormal, Alpha, Iter, Closure, Virtual, Simm, RegAlloc, Asm

If you forget this list, type:

```bash
$ make debuglist
```

You can also use debugasm, debugtest, and debugcmp. Read Makefile.

To compile raytracer, use

```bash
$ make raytracer
```

Use -server option when you run raytracer on the contest server.

```bash
$ make raytracer
$ cd raytracer
$ asm -format o min-rt.cat.s > min-rt.o
$ rin -i sld/contest.sld -o min-rt.ppm min-rt.o -r
$ convert min-rt.ppm min-rt.png
```

----

An educational compiler for a minimal subset of OCaml, written in
~2000 lines of OCaml.  For details, see:

http://esumii.github.io/min-caml/ (Japanese Web page)

http://esumii.github.io/min-caml/jpaper.pdf (Japanese academic paper)

http://esumii.github.io/min-caml/index-e.html (English Web page)

http://esumii.github.io/min-caml/paper.pdf (English academic paper)

1. Install OCaml (http://caml.inria.fr/) if you haven't

2. Download (and expand) MinCaml, e.g.
   git clone https://github.com/esumii/min-caml.git

3. cd min-caml/

4. Execute ./to_x86 for x86
   (or ./to_sparc for SPARC, ./to_ppc for PowerPC)

5. make

6. If you like, try the ray tracer

     cd min-rt/ ; make

   though it takes time because of OCaml bytecode (for testing by
   comparison), not MinCaml

[Updates on October 9, 2013]

- Moved from SourceForge https://sourceforge.net/p/min-caml/code/ to
  GitHub https://github.com/esumii/min-caml

- Merged the Mac OS patch by shinh
  https://twitter.com/shinh/status/322043108021907458

[Update on July 24, 2012]

- 32-bit x86 (with SSE2, that is, Pentium IV or later) is now
  supported (on Linux and Cygwin); execute ./to_x86 before make.

[Updates on September 17, 2008]

- PowerPC is now supported (in addition to SPARC), thanks to
  Ms. Masuko and Prof. Asai in Ochanomizu University.  You _must_
  execute either ./to_ppc or ./to_sparc _before_ make.

- The register allocator now uses a simpler algorithm.  It omits the
  backtracking (ToSpill and NoSpill) in previous versions.
