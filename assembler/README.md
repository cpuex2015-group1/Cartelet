# assembler

## How To Use
このディレクトリ内で make 後

- バイナリを吐く
    - `$ ./asm -format o pohe.s > pohe.o`
- hex を吐く (cutecom で簡単なプログラムを送るときに便利)
    - `$ ./asm -format h pohe.s > pohe.h`
- top\_tb.vhd にコピペできるものを吐く
    - `$ ./asm -format s pohe.s > pohe.sim`
