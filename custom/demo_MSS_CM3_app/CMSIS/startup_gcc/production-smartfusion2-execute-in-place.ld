/*******************************************************************************
 * SmartFusion2 M2S010 application linker script (ISP-safe isolation model)
 *
 * Goals:
 *  - Vector table fixed in ROM (no RAM vector relocation)
 *  - ISP/program-service SRAM window strictly reserved and never touched by app
 *  - Strong linker ASSERTs for overlap/overflow detection
 *  - Explicit symbols for crt0 copy/zero loops (app sections only)
 ******************************************************************************/

OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(Reset_Handler)
GROUP(-lc -lgcc -lm)
SEARCH_DIR(.)
__DYNAMIC = 0;

/*==============================================================================
 * MEMORY MAP
 *  - rom      : non-volatile image storage
 *  - isp_ram  : MSS_SYS / ISP exclusive scratch+runtime (NO app placement)
 *  - app_ram  : application runtime RAM only
 *============================================================================*/
MEMORY
{
    rom      (rx)  : ORIGIN = 0x00000000, LENGTH = 256K
    isp_ram  (rwx) : ORIGIN = 0x20000000, LENGTH = 16K
    app_ram  (rwx) : ORIGIN = 0x20004000, LENGTH = 40K
}

/*==============================================================================
 * CONFIG
 *============================================================================*/
MIN_SIZE_HEAP = 2K;
STACK_SIZE    = 8K;

/* Top of application stack (only in app_ram) */
_estack = ORIGIN(app_ram) + LENGTH(app_ram);

/*==============================================================================
 * SECTIONS
 *============================================================================*/
SECTIONS
{
    /*--------------------------------------------------------------------------
     * Vector table FIXED in ROM
     *--------------------------------------------------------------------------
     * Keep vectors in ROM so program mode cannot corrupt active vectors in SRAM.
     */
    .isr_vector : ALIGN(8)
    {
        __vector_table_start__ = .;
        KEEP(*(.isr_vector))
        . = ALIGN(8);
        __vector_table_end__ = .;
    } > rom

    /* Alias often expected by startup code */
    PROVIDE(__Vectors = __vector_table_start__);
    PROVIDE(__Vectors_End = __vector_table_end__);
    PROVIDE(__Vectors_Size = __vector_table_end__ - __vector_table_start__);

    /*--------------------------------------------------------------------------
     * Code + read-only data in ROM
     *--------------------------------------------------------------------------*/
    .text : ALIGN(8)
    {
        __text_start__ = .;
        CREATE_OBJECT_SYMBOLS
        *(.text .text.* .gnu.linkonce.t.*)
        KEEP(*(.init))
        KEEP(*(.fini))
        . = ALIGN(8);
        __text_end__ = .;
    } > rom

    .rodata : ALIGN(8)
    {
        __rodata_start__ = .;
        *(.rodata .rodata.* .gnu.linkonce.r.*)
        . = ALIGN(8);
        __rodata_end__ = .;
    } > rom

    /* Exception tables (if used by toolchain/libgcc) */
    .ARM.extab : ALIGN(8)
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
        . = ALIGN(8);
    } > rom

    .ARM.exidx : ALIGN(8)
    {
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
        . = ALIGN(8);
    } > rom

    /*--------------------------------------------------------------------------
     * Initialized data in APP RAM, loaded from ROM
     *--------------------------------------------------------------------------*/
    .data : ALIGN(8)
    {
        __data_start__ = .;
        *(.data .data.* .gnu.linkonce.d.*)
        . = ALIGN(8);
        __data_end__ = .;
    } > app_ram AT> rom

    /* crt0 copy symbols */
    __data_load__ = LOADADDR(.data);
    __data_size__ = SIZEOF(.data);

    /*--------------------------------------------------------------------------
     * Zero-init in APP RAM only
     *--------------------------------------------------------------------------*/
    .bss (NOLOAD) : ALIGN(8)
    {
        __bss_start__ = .;
        *(.bss .bss.* .gnu.linkonce.b.*)
        *(COMMON)
        . = ALIGN(8);
        __bss_end__ = .;
    } > app_ram

    __bss_size__ = SIZEOF(.bss);

    /*--------------------------------------------------------------------------
     * Optional no-init app variables (retain across soft reset)
     *--------------------------------------------------------------------------*/
    .noinit (NOLOAD) : ALIGN(8)
    {
        __noinit_start__ = .;
        *(.noinit .noinit.*)
        . = ALIGN(8);
        __noinit_end__ = .;
    } > app_ram

    /*--------------------------------------------------------------------------
     * Heap in APP RAM
     *--------------------------------------------------------------------------*/
    .heap (NOLOAD) : ALIGN(8)
    {
        __heap_start__ = .;
        . += MIN_SIZE_HEAP;
        . = ALIGN(8);
        __heap_end__ = .;
    } > app_ram

    /*--------------------------------------------------------------------------
     * Stack in APP RAM (top-down, fixed)
     *--------------------------------------------------------------------------*/
    .stack (NOLOAD) :
    {
        __stack_top__ = ORIGIN(app_ram) + LENGTH(app_ram);
        __stack_bottom__ = __stack_top__ - STACK_SIZE;
        . = __stack_bottom__;
        . = ALIGN(8);
        __stack_start__ = .;
        . = __stack_top__;
        __stack_end__ = .;
    } > app_ram

    /* Legacy aliases some startup/newlib ports expect */
    PROVIDE(_stack = __stack_top__);
    PROVIDE(_stack_top = __stack_top__);
    PROVIDE(_stack_bottom = __stack_bottom__);
    PROVIDE(__StackTop = __stack_top__);
    PROVIDE(__StackLimit = __stack_bottom__);

    /*--------------------------------------------------------------------------
     * ISP RESERVED WINDOW (exclusive to programmer / MSS_SYS)
     *--------------------------------------------------------------------------
     * App never places anything here except explicitly-tagged ISP buffers.
     * Keep NOLOAD so crt0 will not copy/clear this section.
     */
    .isp_buffer (NOLOAD) : ALIGN(8)
    {
        __isp_buffer_start__ = .;
        KEEP(*(.isp_buffer .isp_buffer.*))
        . = ALIGN(8);
        __isp_buffer_end__ = .;
    } > isp_ram

    __isp_buffer_size__ = SIZEOF(.isp_buffer);

    /*--------------------------------------------------------------------------
     * End markers
     *--------------------------------------------------------------------------*/
    __app_ram_start__ = ORIGIN(app_ram);
    __app_ram_end__   = ORIGIN(app_ram) + LENGTH(app_ram);
    __isp_ram_start__ = ORIGIN(isp_ram);
    __isp_ram_end__   = ORIGIN(isp_ram) + LENGTH(isp_ram);

    /* End of normal app allocations before fixed stack-top region check */
    __app_alloc_end__ = __heap_end__;

    /*--------------------------------------------------------------------------
     * Debug / DWARF
     *--------------------------------------------------------------------------*/
    .stab          0 (NOLOAD) : { *(.stab) }
    .stabstr       0 (NOLOAD) : { *(.stabstr) }
    .debug         0 : { *(.debug) }
    .line          0 : { *(.line) }
    .debug_srcinfo 0 : { *(.debug_srcinfo) }
    .debug_sfnames 0 : { *(.debug_sfnames) }
    .debug_aranges 0 : { *(.debug_aranges) }
    .debug_pubnames 0 : { *(.debug_pubnames) }
    .debug_info    0 : { *(.debug_info .gnu.linkonce.wi.*) }
    .debug_abbrev  0 : { *(.debug_abbrev) }
    .debug_line    0 : { *(.debug_line) }
    .debug_frame   0 : { *(.debug_frame) }
    .debug_str     0 : { *(.debug_str) }
    .debug_loc     0 : { *(.debug_loc) }
    .debug_macinfo 0 : { *(.debug_macinfo) }

    .note.gnu.arm.ident 0 : { KEEP(*(.note.gnu.arm.ident)) }
    .ARM.attributes     0 : { KEEP(*(.ARM.attributes)) }

    /DISCARD/ : { *(.note.GNU-stack) }
}

/*==============================================================================
 * HARD ASSERTIONS (fail link if unsafe)
 *============================================================================*/

/* Physical memory windows must not overlap */
ASSERT((ORIGIN(app_ram) >= (ORIGIN(isp_ram) + LENGTH(isp_ram))) ||
       ((ORIGIN(app_ram) + LENGTH(app_ram)) <= ORIGIN(isp_ram)),
       "ERROR: app_ram overlaps isp_ram");

/* App allocs (data+bss+noinit+heap) must stay below stack bottom */
ASSERT(__app_alloc_end__ <= __stack_bottom__,
       "ERROR: app sections/heap overlap stack");

/* Stack size sanity */
ASSERT(STACK_SIZE <= LENGTH(app_ram),
       "ERROR: STACK_SIZE exceeds app_ram size");

/* ISP section must fit entirely in isp_ram */
ASSERT(__isp_buffer_end__ <= __isp_ram_end__,
       "ERROR: .isp_buffer exceeds isp_ram");

/* Data load image must be in ROM */
ASSERT(__data_load__ >= ORIGIN(rom) &&
       (__data_load__ + __data_size__) <= (ORIGIN(rom) + LENGTH(rom)),
       "ERROR: .data load image is outside ROM");

/* Vector table must be in ROM */
ASSERT(__vector_table_start__ >= ORIGIN(rom) &&
       __vector_table_end__ <= (ORIGIN(rom) + LENGTH(rom)),
       "ERROR: vector table is not fully in ROM");