CPU実験用レイトレーサです。

事前準備

- この上の階層で`make raytrace`して`raytracer/min-rt.cat.s`を生成する。
- アセンブラおよびシミュレータのフォルダ上で`make`して`asm`および`rin`を生成する。
- ImageMagickの`convert`コマンドを使えるようにする(PPMファイルをPNGファイルに変換するために使っています)。

以下の`make`が使用可能です。

- `make` : アセンブラで`min-rt.cat.s`をオブジェクトファイル`min-rt.o`にします。
- `make contest` : `sld/contest.sld`をシミュレータ上でレイトレースし、PPMファイルとPNGファイルをそれぞれ`ppm/contest.ppm`と`png/contest.png`に出力します。
- `make all` : `sld`フォルダ以下の殆どのSLDファイルを全てレイトレースし、`ppm`フォルダと`png`フォルダに出力します。`-j`オプションをつかって並列実行することをオススメします。
- `make ppm/POHE.ppm` : `sld/POHE.sld`をレイトレースし`ppm/POHE.ppm`に出力します。`make png/POHE.png`もできます。
- `make clean` : `min-rt.o`を削除します。
- `make clean_all` : `min-rt.o`と全てのPPM / PNGファイルを削除します。
