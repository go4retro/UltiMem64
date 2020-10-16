# UltiMem64 

A 2 IC SRAM replacement for the Commodore 64 that offers all of the advantages of the VSP-fixed 64kB SRAM modules plus 2 megabytes of directly accessible RAM using a full featured memory management unit (MMU).

## Introduction

UltiMem64 replace the 2 4464 DRAM ICs on newer Commodore 64 motherboards (and can be installed in older 8-IC 4164 DRAM based motherboards using the DRAMCarrier PCB) and provides access to 2 megabytes of direct memory access (not REU access). The memory is instantly available when requested, no DMA needed.  The Color RAM IC installs in the 2114 space on motherboards containing a 2114 Color RAM and provides access to 64 kilobytes of Color memory nybbles.

## Technical Details

(*Although this information is currently correct, it may change based on developer feedback*)

The Commodore 64 64kB address space is partitioned into 16 4kB "pages", corresponding to the first nybble of a 16 bit address (the 'D' in $D0FF). The 2MB SRAM is likewise also partitioned into 4kB pages, which can then be mapped into any (or all) of the 16 slots in the MMU.

The MMU also supports the concept of a "mapping set", which means the developer can arrange up to 256 different 16 slot memory mappings, and choose any one of them at will.  Swapping out 64kB of RAM can take as little as 4 cycles (sta MAPPING_REG).

The system starts up in "hidden" mode, where the registers cannot be set or read from memory.  Reading some "magic addresses" will unhide the registers:

- $C0AA
- $C055
- $C0FF
- $C000
- $CO<PAGE>, where <page> is the high byte of the location where the registers should appear ($FF would place the registers at $ff00-)

Once the registers are visible, the are as follows:

| Register           | Bit  | Note                                       |
| ------------------ | ---- | ------------------------------------------ |
| BASE               | 0    | MMU enabled                                |
| BASE+1             | 7:0  | MMU mapping "window"                       |
| BASE+2             | 7:0  | MMU mapping in use                         |
| BASE+3             | 6:0  | Color RAM 1kB mapping                      |
| BASE+10 to BASE+1F | 7:0  | Low bits of 16 MMU mappings (16 mappings)  |
| BASE+20 to BASE+2F | 7:0  | High bits of 16 MMU mappings (16 mappings) |

To map memory, set the mapping "window" to the set you wish to change, and then alter the data in values BASE+10 to BASE+2F.  To run the code in that mapping, set the value of the map usage register to the desired map number (0-255).

Currently, to hide the registers, simply read the magic memory locations again and set the <page> to be 0.

The MMU replaces the upper 4 bits of the 16 bit memory address with the 9 bits of data from the mapping registers, using the upper 4 bits as a 0-15 "index" into the mapping set (mapping 0 will be used for memory access in the $0XXX range, etc.).  When the MMU is off, only the first 64kB of the SRAM is visible.

Since any mapping can point to any 4kB space in the real address space, one can place the same memory bank in multiple locations in the address map (map $123C00 so it appears at $4C00 and $FC00) or other interesting combinations.

The Color RAM mapping is simpler, and is simply a 6 bit value that choose which of the 64 1kB Color RAM "pages" will be used for the Color RAM data. There is no way to set Color RAM without switching to that specific mapping, so it is best to populate/change Color RAM during video blanking periods.

## Future Directions:

- Expand SRAM to 8MB (Alliance offers an 8MB SRAM in the same footprint)
- Utilize top two bits of MMU mapping to set read/write and IRQ on write flags for any 5kB page.
- Support a way to set mapping set without unhiding all registers (like 128 does)
- Possibly support a way to support auto-incremented memory store/read.

## License
Copyright (C) 2019-20  RETRO Innovations

These files are free designs; you can redistribute them and/or modify
them under the terms of the Creative Commons Attribution-ShareAlike 
4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.

These files are distributed in the hope that they will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
license for more details.


