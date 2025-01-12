# Minimal-OS-Storage-Management

This project implements storage management for a minimal operating system, written in x86 assembly AT&T. It features two distinct memory layouts (unidimensional and bidimensional), each with a set of core operations, and includes a `CONCRETE` functionality for dynamic file loading via UNIX syscalls. The project demonstrates low-level memory handling and is an excellent educational resource for understanding operating system fundamentals.

---

## Features

- **Unidimensional Memory Management**:
  - Allocate contiguous blocks for file storage.
  - Retrieve file block ranges by descriptor.
  - Delete files and free memory blocks.
  - Compact memory through defragmentation.

- **Bidimensional Memory Management**:
  - Store files in a 2D grid of memory blocks.
  - Retrieve memory ranges using start and end coordinates.
  - Perform bidimensional defragmentation to optimize memory usage.

- **Dynamic File Addition with CONCRETE**:
  - Uses UNIX syscalls to load real files from a specified directory.
  - Dynamically calculates descriptors and file sizes.
  - Handles descriptor conflicts and skips redundant entries.

---

## Functions

### Common Functions (Unidimensional and Bidimensional)

#### **ADD (Add File)**
- Allocates memory blocks for files.
- Checks for available space and allocates contiguous memory if possible.
- Outputs the range of allocated blocks or `(0, 0)` if the operation fails.

#### **GET (Retrieve File)**
- Locates a file in memory using its descriptor.
- Outputs the memory range where the file resides or `(0, 0)` if not found.

#### **DELETE (Delete File)**
- Frees memory occupied by a file identified by its descriptor.
- Ensures the memory becomes available for future allocations.

#### **DEFRAGMENTATION**
- Compacts memory to reduce fragmentation:
  - For unidimensional memory, moves files to the beginning of the block.
  - For bidimensional memory, consolidates files towards the top-left corner of the grid.

---

### Bidimensional-Specific Functionality

#### **CONCRETE**
- Dynamically loads files from a directory into memory.
- Uses **UNIX syscalls** for raw file operations:
  1. **Open Directory**: Uses `open` syscall to access the specified path.
  2. **Read Metadata**: Retrieves file sizes and calculates descriptors using modulo arithmetic (`(fd % 255) + 1`).
  3. **Add Files**: Allocates memory for valid files, skipping duplicates or those exceeding capacity.
- Outputs:
  - File descriptor, size, and memory range for each added file.
  - `(0, 0)` for skipped files due to descriptor conflicts or insufficient space.

**Example Input:**
```
5
/path/to/directory
```

## Technical Details

### System Architecture

1. **Unidimensional Memory**:
  - Linear array of fixed-size blocks.
  - Uses contiguous allocation for simplicity and efficiency.
  
2. **Bidimensional Memory**:
  - 2D grid structure with row-major storage.
  - Allows allocation of rectangular memory regions.

3. **Syscalls for CONCRETE**:
  - Implements raw open, stat, and read syscalls.
  - Avoids standard library functions to maintain low-level control.

## Usage

### Compilation

Ensure you have GCC installed. Compile the code as follows:

`gcc -m32 -no-pie Bidimensional.s bidimensional`

### Input Format

- Each operation is specified with its ID:
  - 1: ADD
  - 2: GET
  - 3: DELETE
  - 4: DEFRAGMENTATION
  - 5: CONCRETE (bidimensional only)
 
#### Example Input:
```
5 *How many actions*
5 *Concrete action id*
/path/to/files *Concrete argument*
1 *Add action id*
2 *How many files to add*
101 *First file descriptor*
32 *First file dimension*
102 *Second file descriptor*
64 *Second file dimension*
2 *Get action id*
101 *File descriptor to get*
3 *Delete action id*
101 *File descriptor to delete*
4 *Defragmentation action id*
```

---

### License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---
