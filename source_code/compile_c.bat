@ECHO OFF
sdcc -mmcs51 --iram-size 256 --xram-size 65535 --code-size 65535  --nooverlay --noinduction --verbose --debug -V --std-sdcc89 --model-small   "main_c.c"