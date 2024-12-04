.data
    O: .space 4
    N: .space 4
    file_id: .space 4
    file_dimension: .space 4
    action_id: .space 4

    storage: .space 1024
    storage_size: .long 1024

    add_returned_array: .space 1024
    add_returned_array_index: .long 0

    format_input: .asciz "%d"
    format_add_output: .asciz "%d: (%d, %d)\n"


.global main

add:
    pushl %ebp
    movl %esp, %ebp

    # Reset the returned array index
    movl $0, add_returned_array_index

    # Read how many files to add in N
    pushl $N
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    # Calculate how many inputs are needed next. File id and file dimension for each file. 2N in total -> %ecx
    movl N, %eax
    xorl %edx, %edx
    movl $2, %ecx
    mull %ecx

    movl %eax, %ecx

    movl add_returned_array, %esi

add_loop:
    cmp $0, %ecx
    je add_end

    # Read file id
    pushl $file_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    # Read file dimension
    pushl $file_dimension
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    # Calculate the blocks needed in %eax
    pushl %ecx
    movl file_dimension, %eax
    xorl %edx, %edx
    movl $8, %ecx
    divl %ecx
    popl %ecx
    
    # Ceil for %eax if it is the case, if not skip
    cmp $0, %edx
    jne add_ceil

    jmp add_skip_ceil

add_ceil
    incl %eax

add_skip_ceil:
    # Find free blocks
    pushl %ecx

    xorl %ecx, %ecx
    movl %eax, %edx

add_find_free_space_loop:
    cmp $0, (%edi, %ecx, 4)
    je add_find_continue
    jne add_no_free_block

add_find_continue:
    incl %ecx
    cmp %ecx, %edx
    jne add_find_free_space_loop
    je add_found_space_for_this_file
    
add_no_free_block:
    cmp storage_size, %edx
    # TODO: De verificat daca trebuie sa fie fix egal sau cu -1 
    je add_no_space_for_this_file

    incl %ecx
    icnl %edx
    jmp add_find_free_space_loop

add_no_space_for_this_file:
    movl add_returned_array_index, %ecx

    movl file_id, (%esi, %ecx, 4)
    incl %ecx
    movl $0, (%esi, %ecx, 4)
    incl %ecx
    movl $0, (%esi, %ecx, 4)

    addl $3, add_returned_array_index

    jmp add_repeat_loop

add_found_space_for_this_file:
    # Calculate again the start index in %eax
    subl %eax, %ecx
    movl %ecx, %eax

    movl add_returned_array_index, %ecx

    movl file_id, (%esi, %ecx, 4)
    incl %ecx
    movl %ecx, (%esi, %ecx, 4)
    incl %ecx
    movl %edx, (%esi, %ecx, 4)
    
    # TODO: De completat si storage cu id ul fisierului pe dimensiunea fisierului

    addl $3, add_returned_array_index

add_repeat_loop:
    popl %ecx
    decl %ecx
    
    jmp add_loop

add_end:
    popl %ebp
    ret

get:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax

    movl 
    
main:
    movl storage, %edi
    xorl %ecx, %ecx

    movl $0, (%edi, %ecx, 4)
    incl %ecx
    cmp storage_size, %ecx
    jne main

    pushl $O
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

et_do_action:
    pushl $action_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    cmp $1, action_id
    je et_add

    cmp $2, action_id
    je et_get

    cmp $3, action_id
    je et_delete

    cmp $4, action_id
    je et_defrag

et_add:
    pushl O
    call add
    popl %ebx

    # %eax = 3N, %ecx = 0 => %ecx < 3N (3N - 3) Array index starts from 0
    movl N, %eax
    movl $3, %ecx
    mull %ecx

    xorl %ecx, %ecx

et_print_add_loop:
    movl %ecx, %ebx
    addl $1, %ebx
    movl %ecx, %edx
    addl $2, %edx

    pushl (%esi, %edx, 4)
    pushl (%esi, %ebx, 4)
    pushl (%esi, %ecx, 4)
    pushl $format_add_output
    movl 
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    addl $3, %ecx
    cmp %eax, %ecx
    jne et_print_add_loop
    je et_decl_O

et_get:
    pushl $file_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    pushl file_id
    call get
    popl %ebx

et_decl_O:
    decl O
    cmp $0, O
    je et_exit
    jne et_do_action

et_exit:
    pushl $0
    call fflush
    popl %eax

    movl $1, %eax
    xorl %ebx, %ebx
    int $0x80
