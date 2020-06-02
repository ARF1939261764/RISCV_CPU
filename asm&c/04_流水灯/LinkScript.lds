ENTRY(_start)
SECTIONS {
    . = 0;
    __text_start = .;
    . = ALIGN(4);    
    .text               :                      {*(.text)}
    . = ALIGN(4);
    .rodata             :                      {*(.rodata)}
    . = ALIGN(4);
    .data               :                      {*(.data)}    
    . = ALIGN(4);
    __bss_start = .;
    .bss                :                      { *(.bss)  *(COMMON) }
    . = ALIGN(4);
    __bss_end = .;
}