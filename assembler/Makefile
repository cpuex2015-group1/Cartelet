all: asm
asm: main.ml
	ocamlopt.opt -o asm str.cmxa main.ml
.PHONY: clean
clean:
	rm -f asm *.o *.cmi *.cmx
