/*
 * File header 
 */
struct Elf32_Header {
	unsigned char   e_ident[16];
	uint16_t        e_type;	/* Relocatable=1, Executable=2 (+ some
				 * more ..) */
	uint16_t        e_machine;	/* Target architecture: MIPS=8 */
	uint32_t        e_version;	/* Elf version (should be 1) */
	uint32_t        e_entry;	/* Code entry point */
	uint32_t        e_phoff;	/* Program header table */
	uint32_t        e_shoff;	/* Section header table */
	uint32_t        e_flags;	/* Flags */
	uint16_t        e_ehsize;	/* ELF header size */
	uint16_t        e_phentsize;	/* Size of one program segment
					 * header */
	uint16_t        e_phnum;	/* Number of program segment
					 * headers */
	uint16_t        e_shentsize;	/* Size of one section header */
	uint16_t        e_shnum;	/* Number of section headers */
	uint16_t        e_shstrndx;	/* Section header index of the
					 * string table for section header 
					 * * names */
};

/*
 * Section header 
 */
struct Elf32_Shdr {
	uint32_t        sh_name;
	uint32_t        sh_type;
	uint32_t        sh_flags;
	uint32_t        sh_addr;
	uint32_t        sh_offset;
	uint32_t        sh_size;
	uint32_t        sh_link;
	uint32_t        sh_info;
	uint32_t        sh_addralign;
	uint32_t        sh_entsize;
};

/*
 * Program header 
 */
struct Elf32_Phdr {
	uint32_t p_type;	/* Segment type: Loadable segment = 1 */
	uint32_t p_offset;	/* Offset of segment in file */
	uint32_t p_vaddr;	/* Reqd virtual address of segment 
					 * when loading */
	uint32_t p_paddr;	/* Reqd physical address of
					 * segment (ignore) */
	uint32_t p_filesz;	/* How many bytes this segment
					 * occupies in file */
	uint32_t p_memsz;	/* How many bytes this segment
					 * should occupy in * memory (when 
					 * * loading, expand the segment
					 * by * concatenating enough zero
					 * bytes to it) */
	uint32_t p_flags;	/* Flags: logical "or" of PF_
					 * constants below */
	uint32_t p_align;	/* Reqd alignment of segment in
					 * memory */
};

/*
 * constants for Elf32_Phdr.p_flags 
 */
#define PF_X		1	/* readable segment */
#define PF_W		2	/* writeable segment */
#define PF_R		4	/* executable segment */

/*
 * constants for indexing into Elf64_Header_t.e_ident 
 */
#define EI_MAG0		0
#define EI_MAG1		1
#define EI_MAG2		2
#define EI_MAG3		3
#define EI_CLASS	4
#define EI_DATA		5
#define EI_VERSION	6

#define ELFMAG0         '\177'
#define ELFMAG1         'E'
#define ELFMAG2         'L'
#define ELFMAG3         'F'

#define ELFCLASS32      1
#define ELFCLASS64      2

#define PT_NULL 0
#define PT_LOAD 1
#define PT_DYNAMIC 2
#define PT_INTERP 3
#define PT_NOTE 4

#define ELFDATA2LSB 1
#define ELFDATA2MSB 2

#define EM_ARM 40
#define EM_BLACKFIN 106
#define EM_MIPS 8
#define EM_COLDFIRE 52
#define EM_PPC 20
