#ifndef _WDOS_KERNEL_DRIVER_VGA_H_
#define _WDOS_KERNEL_DRIVER_VGA_H_

#include <runtime/types.h>
#include <mm/mm.h>
#include <tty.h>

#define CRTC_ADDRESS 0x3D4
#define CRTC_DATA 0x3D5
#define CRTC_START_ADDRESS_HIGH 0xC
#define CRTC_START_ADDRESS_LOW 0xD
#define CRTC_CURSOR_LOCATION_HIGH 0xE
#define CRTC_CURSOR_LOCATION_LOW 0xF

#define VGA_GRAPHICS_MEMORY_START_ADDRESS __VA((void *)0xb8000)
#define VGA_WIDTH  80
#define VGA_HEIGHT 25

void init_vga();
void vga_set_start_address(uint16_t *gm);
void vga_set_cursor_location(uint8_t x, uint8_t y);

// for tty driver
void vga_tty_init(tty_t *tty, size_t i);
void vga_tty_switch_handler(tty_t *tty);
void vga_tty_update_cursor_location(tty_t *tty);
const tty_driver_t *vga_get_tty_driver();

#endif // _WDOS_KERNEL_DRIVER_VGA_H_
