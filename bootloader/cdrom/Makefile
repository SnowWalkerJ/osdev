CC = gcc
AS = nasm
LD = ld

CFLAGS = -g -m32 -fno-stack-protector -fno-builtin -fno-asynchronous-unwind-tables \
         -nostdlib -nostdinc -Wall -Wextra -I. -I../../
ASFLAGS = -felf32
LDFLAGS = -z max-page-size=0x1000 -melf_i386 -T linker.ld

stage2.bin: stage2.elf
	objcopy -j .text -O binary stage2.elf stage2.bin

stage2.elf: linker.ld stage2.o blmain.o bios.o iso9660.o ../../stdlib/memory.o ../../stdlib/string.o
	$(LD) $(LDFLAGS) $^ -o $@

blmain.o: blmain.c
	$(CC) $(CFLAGS) -c $^ -o $@

bios.o: bios.c
	$(CC) $(CFLAGS) -c $^ -o $@

iso9660.o: iso9660.c
	$(CC) $(CFLAGS) -c $^ -o $@

stage2.o: stage2.asm
	$(AS) $(ASFLAGS) $^ -o $@

stage1: stage1.asm
	$(AS) $^ -o $@

.PHONY: clean
clean:
	-rm *.bin
	-rm stage1
	-rm *.o
	-rm *.elf
	-rm *.iso
	