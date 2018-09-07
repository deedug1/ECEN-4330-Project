@ECHO OFF
set target=./target
cd target
sdcc -mmcs51 --iram-size 256 --xram-size 65535 --code-size 65535  --nooverlay --noinduction --verbose --debug -V --std-sdcc89 --model-small   "../src/main_c.c"