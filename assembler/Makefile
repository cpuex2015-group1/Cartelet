all: asm
asm:
	ocamlopt -o asm str.cmxa main.ml
.PHONY: clean
clean:
	rm asm *.o *.cmi *.cmx
