SECTIONS {
    . = 0;
    text_start = .;
    . = ALIGN(4);    
    .text               :                      {*(.text)}
    . = ALIGN(4);
    .rodata             :                      {*(.rodata)}
    . = ALIGN(4);
    .data               :                      {*(.data)}    
    . = ALIGN(4);
    bss_start = .;
    .bbs                :                      {*(.bbs) *(.COMMON)}
    bss_end = .;           
}