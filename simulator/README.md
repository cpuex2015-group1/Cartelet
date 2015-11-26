Rin : simulator for Cartelet
=========

使い方  
make  
./rin [options] filename  

オプション  
-h : help  
-s : step exec  
-i [filename] : recv8のデータを[filename]（バイナリファイル）から読み込み  
-o [filename] : send8のデータを[filename]（バイナリファイル）に出力  
-r : 結果のみを表示  
-b : GPRを2進数で表示  
-x : GPRを16進数で表示  
-f : FPUをx86に切り替える  

step実行時コマンド　（入力時[]はつけない）  
h , help : help  
r , run : run  
s , step : step  
b [addr] : [addr]にbreakpointを設定  
bi [addr] [n] : はじめの[n]回はbreakpointに達しても停止しない  
binst [instname] : [instname]の命令が来たらbreakする（現在はnopとsend8のみ）  
db [addr] : [addr]に設定したbreakpointを削除  
pg [n] : print GPR [n]  
pf [n] : print FPR [n]  
pm [addr] : print memory [addr]  
pa : print all registers  
ps : print statistics  
pp : print PC  
pb : print breakpoints  
pc : print FPcond  
dg [n] : display GPR [n]  
df [n] : display FPR [n]  
pon/poff : 画面表示on/off  