org 0x7c00
bits 16

jmp 0:_start ; set cs

_start:
cli

;cmp dl, 0xe0 ; is cdrom?
;jnz die

xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00 ; init stack

lea si, [loading_str]
call print

mov ah, 0x41 ; check extension present
mov bx, 0x55aa
int 0x13 ; bios function
cmp bx, 0xaa55
jne not_present

; find primary volume descriptor
mov ebx, 16 ; starts at sector 16
mov ecx, 1
mov ax, 0x1000
mov es, ax
xor di, di ; es:di = 1000:0000 = 0x10000
find_primary_volume_descriptor_loop:
  call read_sector
  cmp byte [es:di + volume_descriptor_type], type_primary_volume_descriptor
  je found_primary_volume_descriptor ; is primary volume descriptor?
  inc ebx
jmp find_primary_volume_descriptor_loop

found_primary_volume_descriptor:
mov ebx, [es:di + primary_volume_descriptor_root_dir_rec + dir_rec_extent_sector_no]
mov ecx, [es:di + primary_volume_descriptor_root_dir_rec + dir_rec_data_length]
shr ecx, 11
; es:di = 1000:0000 = 0x10000
call read_sector

; find boot dir
mov ax, es
mov ds, ax
mov si, di ; ds:si = es:di
mov bx, cx
shl bx, 11 ; limit
lea ax, [boot_dir_name]
call find_entry
test ax, ax
jz path_not_found

mov ebx, [ds:si + dir_rec_extent_sector_no]
mov ecx, [ds:si + dir_rec_data_length]
shr ecx, 11
; es:di = 1000:0000 = 0x10000
call read_sector

; find stage2 file
mov ax, es
mov ds, ax
mov si, di ; ds:si = es:di
mov bx, cx
shl bx, 11
lea ax, [stage2_file_name]
call find_entry
test ax, ax
jz stage2_not_found

; found stage2
mov ebx, [ds:si + dir_rec_extent_sector_no]
mov ecx, [ds:si + dir_rec_data_length]
add ecx, 2047
shr ecx, 11 ; ceiling(length / 2048)
; es:di = 1000:0000 = 0x10000
call read_sector
jmp word 0x1000:0000 ; go!

not_present:
xor ax, ax
mov ds, ax
lea si, [not_present_str]
jmp print_and_die

path_not_found:
xor ax, ax
mov ds, ax
lea si, [path_not_found_str]
jmp print_and_die

stage2_not_found:
xor ax, ax
mov ds, ax
lea si, [stage2_not_found_str]
jmp print_and_die

print_and_die:
call print

die:
cli
hlt
jmp die

print: ; ds:si
lodsb
or al, al
jz print_return
mov ah, 0x0e ; print
mov bh, 0
mov bl, 0
int 0x10 ; bios print
jmp print
print_return:
ret

print_dot:
mov al, '.'
mov ah, 0x0e ; print
mov bh, 0
mov bl, 0
int 0x10 ; bios print
ret

read_sector: ; sector_no = ebx, count = ecx, dest = es:di
xor ax, ax
mov ds, ax
mov [dap_ptr + dap_sector_no_low], ebx
mov [dap_ptr + dap_count], ecx
lea si, [dap_ptr] ; ds:si = dap_ptr
mov ax, es
mov [dap_ptr + dap_seg], ax
mov [dap_ptr + dap_offset], di ; dap_ptr->seg:offset = es:di
mov ah, 0x42 ; extended read sector
int 0x13 ; bios function
push ax ; save ax (set by int 0x13)
call print_dot
pop ax
ret

find_entry: ; buffer = ds:si, count_limit = bx, name_ptr = ax
push di
push es
push bx
mov di, ax
xor ax, ax
mov es, ax
add bx, si
find_entry_loop:
  cmp si, bx ; buffer > limit?
  jae find_entry_return0
  cmp byte [ds:si + dir_rec_length], 0 ; buffer->dir_rec_length == 0?
  je find_entry_return0

  xor cx, cx
  mov cl, [ds:si + dir_rec_ident_length]
  cmp cl, name_min_size ; buffer->dir_rec_ident_length < name_min_size?
  jb find_entry_loop_continue

  xor bp, bp ; i = 0
  strcmp_loop:
    mov cl, [es:bp + di]
    mov ch, [ds:bp + si + dir_rec_ident]
    test cl, cl
    jz strcmp_last
    cmp cl, ch ; cl == ch?
    jne find_entry_loop_continue
    inc bp
  jmp strcmp_loop

  strcmp_last:
  ; (ch == ';' || ch == '\0') || bp == dir_rec_ident_length...
  cmp ch, ';'
  je find_entry_return1
  test ch, ch
  jz find_entry_return1
  cmp bp, dir_rec_ident_length
  je find_entry_return1
  ; else

  find_entry_loop_continue:
  ; next entry
  xor cx, cx
  mov cl, [ds:si + dir_rec_length]
  add si, cx ; buffer += buffer->dir_rec_length
jmp find_entry_loop

find_entry_return0:
xor ax, ax
jmp find_entry_return

find_entry_return1:
mov ax, 1
find_entry_return:
pop bx
pop es
pop di
ret

dap_ptr:
db 16 ; dap size = 16
db 0 ; reversed
dw 1 ; count
dd 0 ; dest
dd 0 ; sector no low
dd 0 ; sector no high

dap_count equ 2
dap_offset equ 4
dap_seg equ 6
dap_sector_no_low equ 8
dap_sector_no_high equ 12

volume_descriptor_type equ 0
type_primary_volume_descriptor equ 0x01

; data struct offset
primary_volume_descriptor_root_dir_rec equ 156
dir_rec_length equ 0
dir_rec_extent_sector_no equ 2
dir_rec_data_length equ 10
dir_rec_ident_length equ 32
dir_rec_ident equ 33

; constant strings
loading_str db "Loading", 0
not_present_str db "Extensions not present.", 0
path_not_found_str db "Path not found.", 0
stage2_not_found_str db "Stage2 not found.", 0

; /BOOT/STAGE2.BIN
name_min_size equ 4 ; length of "BOOT"
boot_dir_name db "BOOT", 0
stage2_file_name db "STAGE2.BIN", 0

times 510 - ($ - $$) db 0 
dw 0xaa55
