%include "descriptor.inc"

global _start
global tss_ptr
global gdt32_tss
global idt_ptr
extern kmain
extern prepare_tss_gdt_entry
extern prepare_idt
extern int_handler

MULTIBOOT_HEADER_MAGIC equ 0x1BADB002
MULTIBOOT_HEADER_FLAGS equ 0
MULTIBOOT_HEADER_CHECKSUM equ -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)
KERNEL_STACK_SIZE equ 0x4000 ; 16KiB

section .bss
align 4
kernel_stack_base:
resb KERNEL_STACK_SIZE

section .text
align 4
bits 32

dd MULTIBOOT_HEADER_MAGIC
dd MULTIBOOT_HEADER_FLAGS
dd MULTIBOOT_HEADER_CHECKSUM

_start:
  nop
  nop
  nop
  nop
  mov edi, eax ; save eax and ebx
  mov esi, ebx
  lgdt [gdt32_ptr]
  jmp selector_kernel_code:_start_kernel
_start_kernel:
  mov ax, selector_kernel_data
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax
  mov esp, kernel_stack_base + KERNEL_STACK_SIZE
  call prepare_idt
  cli
  lidt [idtptr]
  sti
  int 0x0
  jmp $
  ; enter ring3
  ; 1. load tss
  ;mov [tss_ss0], ss
  ;mov [tss_esp0], esp
  ;call prepare_tss_gdt_entry
  ;mov ax, selector_tss
  ;jmp $
  ;ltr ax
  ; 2. use retf
  ;mov eax, esp
  ;push selector_user_data ; ss
  ;push eax                ; esp
  ;push selector_user_code ; cs
  ;push _start_user        ; eip
  ;retf
_start_user:
  ;jmp $
  ;cli ; test ring3
  ;mov ax, selector_user_data
  ;mov ds, ax
  ;mov es, ax
  ;mov fs, ax
  ;mov gs, ax
  push esi
  push edi
  call kmain
  add esp, 8
  cli
  hlt

section .gdt32
align 4

gdt32_none: descriptor 0, 0, 0 ; none
gdt32_kernel_code: descriptor 0, 0xFFFFF, DESCRIPTOR_ATTR_CODE32 | DESCRIPTOR_ATTR_DPL0
gdt32_kernel_data: descriptor 0, 0xFFFFF, DESCRIPTOR_ATTR_DATA32 | DESCRIPTOR_ATTR_DPL0
gdt32_user_code: descriptor 0, 0xFFFFF, DESCRIPTOR_ATTR_CODE32 | DESCRIPTOR_ATTR_DPL3
gdt32_user_data: descriptor 0, 0xFFFFF, DESCRIPTOR_ATTR_DATA32 | DESCRIPTOR_ATTR_DPL3
gdt32_tss: descriptor 0, 0, 0 ; will be filled later, see tss.c

gdt32_length equ $ - gdt32_none
gdt32_ptr:
  dw gdt32_length - 1 ; GDT limit
  dd gdt32_none ; GDT base

selector_kernel_code equ ((gdt32_kernel_code - gdt32_none) | SELECTOR_GDT | SELECTOR_RPL0)
selector_kernel_data equ ((gdt32_kernel_data - gdt32_none) | SELECTOR_GDT | SELECTOR_RPL0)
selector_user_code equ ((gdt32_user_code - gdt32_none) | SELECTOR_GDT | SELECTOR_RPL3)
selector_user_data equ ((gdt32_user_data - gdt32_none) | SELECTOR_GDT | SELECTOR_RPL3)
selector_tss equ ((gdt32_tss - gdt32_none) | SELECTOR_GDT | SELECTOR_RPL0)

tss_ptr:
  dd 0
tss_esp0:
  dd 0
tss_ss0:
  dd 0
tss_esp1:
  times 23 dd 0 ; esp1 ~ iomap_base
tss_length equ $ - tss_ptr

section .idt
align 4

idt_ptr:
%rep 255
  descriptor 0, 0, 0 ; will be filled later, see tss.c
%endrep

idt_length equ $ - idt_ptr
idtptr:
  dw idt_length - 1
  dd idt_ptr
