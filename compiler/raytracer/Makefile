ASM = ../../assembler/asm
SIM = ../../simulator/rin

MINRT_ASM = min-rt.cat.s
MINRT_OBJ = min-rt.o

# SLDファイルの内容が全く同じものがあるので適宜飛ばす
SLD = base pika rot temp eye textest candy hoe hoehoe \
noe charhan2 lattice2 charhan lattice ss20 \
tron ss20-2 contest shuttle piero1

$(MINRT_OBJ): $(MINRT_ASM)
	$(ASM) -format o $(MINRT_ASM) > $@
	ls -lah $(MINRT_OBJ)

.PRECIOUS: $(MINRT_ASM) $(SLD:%=sld/%.sld) $(SLD:%=ppm/%.ppm) $(SLD:%=png/%.png)

ppm/%.ppm: sld/%.sld $(MINRT_OBJ)
	$(SIM) -r -i $< -o $@ $(MINRT_OBJ)
png/%.png: ppm/%.ppm
	convert $< $@

contest: ppm/contest.ppm png/contest.png
all: $(SLD:%=ppm/%.ppm) $(SLD:%=png/%.png)

.PHONY: clean clean_all
clean:
	rm -f $(MINRT_OBJ)
clean_all:
	rm -f $(MINRT_OBJ) ppm/* png/*
