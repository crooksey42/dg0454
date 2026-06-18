/*******************************************************************************
 * (c) Copyright 2015 Microsemi SoC Products Group.  All rights reserved.
 *
 * file name : production-smartfusion2-execute-in-place.ld
 * SmartFusion2 Cortex-M3 linker script.
 *
 * MODIFIED FOR ISP DEMO (run-from-eSRAM):
 *   The application image is LOADED into eNVM (LMA at 0x00000000, so Libero
 *   accepts it into the eNVM data client and FlashPro/the bootloader can store
 *   it), but it RUNS from eSRAM (VMA at 0x20000000).
 *
 *   This is achieved with the "AT>rom" load-vs-run mechanism: .vector_table,
 *   .text and .data have their run-time addresses (VMA) in eSRAM and their
 *   load addresses (LMA) in eNVM. The C startup code copies .data from its LMA
 *   to its VMA and zero-inits .bss, exactly as for a normal "run from RAM"
 *   image.
 *
 *   WHY: Previously every section was placed at ORIGIN 0x00000000 (VMA == LMA),
 *   so the running image only worked because the boot loader remapped eSRAM to
 *   0x00000000. During an IAP/ISP PROGRAM operation the System Controller
 *   changes the eNVM/eSRAM remap state, which moved the ground under the
 *   0x0-based stack/data/code and corrupted the running application (garbage
 *   bytes on the UART, lock-up). AUTHENTICATE/VERIFY do not reprogram eNVM, so
 *   they never disturbed the remap and worked. Linking the run-time addresses
 *   natively at 0x20000000 removes that dependency so PROGRAM no longer
 *   corrupts the running code.
 *
 *   REQUIRED COMPANION CHANGES:
 *     - The boot loader must set SCB->VTOR = 0x20000000 and branch to the
 *       application reset handler at its 0x20000000 address; it must NOT rely
 *       on remapping eSRAM to 0x00000000 for the application to run.
 *     - Regenerate the eNVM .hex from this build and store it at the eNVM
 *       image address used by the boot loader.
 *
 * SVN $Revision: 7683 $
 * SVN $Date: 2015-08-21 17:06:30 +0100 (Fri, 21 Aug 2015) $
 */
OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
GROUP(-lc -lgcc -lm)
OUTPUT_ARCH(arm)
ENTRY(Reset_Handler)
SEARCH_DIR(.)
__DYNAMIC  =  0;

/*******************************************************************************
 * Start of board customization.
 *******************************************************************************/
MEMORY
{
    /*
    * WARNING: The words "SOFTCONSOLE", "FLASH", and "USE", the colon ":", and
    *          the name of the type of flash memory are all in a specific order.
    *          Please do not modify that comment line, in order to ensure
    *          debugging of your application will use the flash memory correctly.
    */

    /* SOFTCONSOLE FLASH USE: microsemi-smartfusion2-envm */
    /* LMA: image is stored/loaded here. eNVM is mapped at 0x00000000 on reset,
     * so linking the load image at 0x00000000 keeps it acceptable to Libero's
     * eNVM data client. */
    rom (rx)  : ORIGIN = 0x00000000, LENGTH = 60k

    /* VMA: image actually executes here after the boot loader copies it into
     * eSRAM. All run-time addresses (code, data, bss, stack, isp_buffer) are
     * resolved natively to this region, so they do not depend on the
     * eSRAM->0x00000000 remap. */
    ram (rwx) : ORIGIN = 0x20000000, LENGTH = 48k
}

RAM_START_ADDRESS   = 0x20000000;   /* Must match MEMORY region ram ORIGIN above (run-time). */
RAM_SIZE            = 48k;           /* Must match MEMORY region ram LENGTH above. */
MAIN_STACK_SIZE     = 4k;            /* Cortex main stack size. */
MIN_SIZE_HEAP       = 0k;           /* needs to be calculated for your application */

/*******************************************************************************
 * End of board customization.
 *******************************************************************************/

PROVIDE (__main_stack_start = RAM_START_ADDRESS + RAM_SIZE);
PROVIDE (__process_stack_start = __main_stack_start - MAIN_STACK_SIZE);
PROVIDE (_estack = __main_stack_start);
PROVIDE (__mirrored_nvm = 0);   /* NVM is not mirrored to VMA address; .data copy is required. */

/*
 * Remap instruction for startup code and debugger:
 *  0: remap eNVM to address 0x00000000
 *  1: remap eSRAM to address 0x00000000
 *  2: remap external DDR memory to address 0x00000000
 *
 * NOTE: With the application now linked to run natively at 0x20000000, the
 * application no longer depends on this remap. The reset/vector base is set via
 * VTOR by the boot loader. Left at 0 here.
 */
PROVIDE (__smartfusion2_memory_remap = 0);

SECTIONS
{
  .vector_table : ALIGN(0x200)
  {
    __vector_table_load = LOADADDR(.vector_table);
    __vector_table_start = .;
    __vector_table_vma_base_address = .;
    KEEP(*(.isr_vector))
    . = ALIGN(0x10);
    _evector_table = .;
  } >ram 

  .boot_code : ALIGN(0x10) /* When all code in NVRAM, no requirement for this section- but adds clarity when looking at .lst file */
  {
    *(.boot_code)
    . = ALIGN(0x10);
  } >ram 

  .text : ALIGN(0x10)
  {
    CREATE_OBJECT_SYMBOLS
    __text_load = LOADADDR(.text);
    __text_start = .;

    *(.text .text.* .gnu.linkonce.t.*)
    *(.plt)
    *(.gnu.warning)
    *(.glue_7t) *(.glue_7) *(.vfp11_veneer)

    . = ALIGN(0x4);
    /* These are for running static constructors and destructors under ELF.  */
    KEEP (*crtbegin.o(.ctors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*crtend.o(.ctors))
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*crtend.o(.dtors))

    *(.rodata .rodata.* .gnu.linkonce.r.*)

    *(.ARM.extab* .gnu.linkonce.armextab.*)
    *(.gcc_except_table)
    *(.eh_frame_hdr)
    *(.eh_frame)

    KEEP (*(.vector_table))
    KEEP (*(.init))
    KEEP (*(.fini))

    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array))
    PROVIDE_HIDDEN (__init_array_end = .);
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(.fini_array))
    KEEP (*(SORT(.fini_array.*)))
    PROVIDE_HIDDEN (__fini_array_end = .);
    . = ALIGN(0x10);
  } >ram 
  /* .ARM.exidx is sorted, so has to go in its own output section.  */
   __exidx_start = .;
  .ARM.exidx :
  {
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
  } >ram 
  __exidx_end = .;
  _etext = .;

  .data : ALIGN(0x10)
  {
    __data_load = LOADADDR(.data);
    _sidata = LOADADDR (.data);
    __data_start = .;
    _sdata = .;
    KEEP(*(.jcr))
    *(.got.plt) *(.got)
    *(.shdata)
    *(.data .data.* .gnu.linkonce.d.*)
    . = ALIGN(0x10);
    _edata = .;
  } >ram 

  .bss : ALIGN(0x10)
  {
    __bss_start__ = . ;
    _sbss = .;
    *(.shbss)
    *(.bss .bss.* .gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN(0x10);
    __bss_end__ = .;
    _end = .;
    __end = _end;
    _ebss = .;
    PROVIDE(end = .);
  } >ram

  /*
   * ISP page buffers (g_page_buffer, isp_page_buffer) are tagged
   * .isp_buffer in the application source. Give them a defined home inside
   * eSRAM. This is run-time only (not part of the loaded eNVM image).
   */
  .isp_buffer : ALIGN(0x10)
  {
    __isp_buffer_start__ = .;
    KEEP(*(.isp_buffer .isp_buffer.*))
    . = ALIGN(0x10);
    __isp_buffer_end__ = .;
  } >ram

  .heap : ALIGN(0x10)
  {
    __heap_start__ = .;
    . += MIN_SIZE_HEAP;         /* will generate error if this minimum size not available */
    . += ((ABSOLUTE(RAM_START_ADDRESS) + RAM_SIZE - MAIN_STACK_SIZE) - .); /* assumes stack starts after heap */
    _eheap = .;
  } >ram

  .stack : ALIGN(0x10)
  {
    __stack_start__ = .;
    . += MAIN_STACK_SIZE;
    _estack = .;
  } >ram

  .stab 0 (NOLOAD) :
  {
    *(.stab)
  }

  .stabstr 0 (NOLOAD) :
  {
    *(.stabstr)
  }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }
  .note.gnu.arm.ident 0 : { KEEP (*(.note.gnu.arm.ident)) }
  .ARM.attributes 0 : { KEEP (*(.ARM.attributes)) }
  /DISCARD/ : { *(.note.GNU-stack)  }
}