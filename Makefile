CC = gcc
AS = nasm
LD = ld

CFLAGS = -g -m32 -fno-stack-protector -fno-builtin -fno-asynchronous-unwind-tables \
         -nostdlib -nostdinc -fno-PIC -fno-PIE -Wall -Wextra -I.
ASFLAGS = -felf32
LDFLAGS = -z max-page-size=0x1000 -melf_i386 -T linker.ld

.PHONY: all
all: os.iso grub.iso
	

.PHONY: bootloader/cdrom/stage2.bin
bootloader/cdrom/stage2.bin: bootloader/cdrom/stage2.asm stdlib/memory.o stdlib/string.o
	cd bootloader/cdrom && make stage2.bin

.PHONY: bootloader/cdrom/stage1
bootloader/cdrom/stage1: bootloader/cdrom/stage1.asm
	cd bootloader/cdrom && make stage1

os.iso: kernel.elf bootloader/cdrom/stage1 bootloader/cdrom/stage2.bin cmdline.txt
	cp kernel.elf iso/boot
	cp cmdline.txt iso/boot
	cp bootloader/cdrom/stage1 iso/boot
	cp bootloader/cdrom/stage2.bin iso/boot
	mkisofs -R -b boot/stage1 -no-emul-boot -V WDOS -v -o os.iso iso

loader.o: loader.asm
	$(AS) $(ASFLAGS) $^ -o $@

kmain.o: kmain.c
	$(CC) $(CFLAGS) -c $^ -o $@

asm.o: asm.c
	$(CC) $(CFLAGS) -c $^ -o $@

tty.o: tty.c
	$(CC) $(CFLAGS) -c $^ -o $@

pm.o: pm.c
	$(CC) $(CFLAGS) -c $^ -o $@

interrupt.o: interrupt.c
	$(CC) $(CFLAGS) -c $^ -o $@

syscall.o: syscall.c
	$(CC) $(CFLAGS) -c $^ -o $@

io.o: io.c
	$(CC) $(CFLAGS) -c $^ -o $@

syscall_impl.o: syscall_impl.c
	$(CC) $(CFLAGS) -c $^ -o $@

thread.o: thread.c
	$(CC) $(CFLAGS) -c $^ -o $@

idle.o: idle.c
	$(CC) $(CFLAGS) -c $^ -o $@

dwm.o: dwm.c
	$(CC) $(CFLAGS) -c $^ -o $@

driver/pic8259a.o: driver/pic8259a.c
	$(CC) $(CFLAGS) -c $^ -o $@

driver/pit8253.o: driver/pit8253.c
	$(CC) $(CFLAGS) -c $^ -o $@

driver/keyboard.o: driver/keyboard.c
	$(CC) $(CFLAGS) -c $^ -o $@

driver/vga.o: driver/vga.c
	$(CC) $(CFLAGS) -c $^ -o $@

driver/vesa.o: driver/vesa.c
	$(CC) $(CFLAGS) -c $^ -o $@

driver/vga_font.o: driver/vga_font.c
	$(CC) $(CFLAGS) -c $^ -o $@

stdlib/memory.o: stdlib/memory.c
	$(CC) $(CFLAGS) -c $^ -o $@

stdlib/string.o: stdlib/string.c
	$(CC) $(CFLAGS) -c $^ -o $@

stdlib/bits.o: stdlib/bits.c
	$(CC) $(CFLAGS) -c $^ -o $@

mm/page_list.o: mm/page_list.c
	$(CC) $(CFLAGS) -c $^ -o $@

mm/buddy.o: mm/buddy.c
	$(CC) $(CFLAGS) -c $^ -o $@

mm/mm.o: mm/mm.c
	$(CC) $(CFLAGS) -c $^ -o $@

mm/page_fault.o: mm/page_fault.c
	$(CC) $(CFLAGS) -c $^ -o $@

mm/paging.o: mm/paging.c
	$(CC) $(CFLAGS) -c $^ -o $@

kernel.elf: linker.ld loader.o kmain.o asm.o tty.o pm.o interrupt.o syscall.o io.o syscall_impl.o thread.o idle.o dwm.o driver/pic8259a.o driver/pit8253.o driver/keyboard.o driver/vga.o driver/vesa.o driver/vga_font.o stdlib/memory.o stdlib/string.o stdlib/bits.o mm/page_list.o mm/buddy.o mm/mm.o mm/page_fault.o mm/paging.o
	$(LD) $(LDFLAGS) $^ -o $@

grub.iso: kernel.elf iso/boot/grub/grub.cfg
	cp kernel.elf iso/boot
	grub-mkrescue --fonts=ascii --locales=en_GB --modules= \
	              --product-name=WDOS --product-version=1.0 -o grub.iso iso

.PHONY: run
run: os.iso
	qemu-system-x86_64 -s -cdrom os.iso -m 1024

.PHONY: debug
debug: os.iso
	bochs -f bochsrc

.PHONY: rungrub
rungrub: grub.iso
	qemu-system-x86_64 -s -cdrom grub.iso -m 1024

.PHONY: debuggrub
debuggrub: grub.iso
	bochs -f bochsrcgrub

.PHONY: gdb
gdb:
	gdb -x gdb_remote

.PHONY: clean
clean:
	-rm *.d
	-rm *.o
	-rm *.elf
	-rm *.iso
	-rm driver/*.o
	-rm mm/*.o
	-rm stdlib/*.o
	cd bootloader/cdrom && make clean
	
