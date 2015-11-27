all: asm
asm: main.ml
	ocamlopt.opt -o asm str.cmxa main.ml
.PHONY: clean
clean:
	rm asm *.o *.cmi *.cmx
