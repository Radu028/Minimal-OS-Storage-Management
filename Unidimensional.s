.data
    O: .space 4
    N: .space 4
    file_id: .space 4
    file_dimension: .space 4
    action_id: .space 4

    storage: .space 1024
    storage_size: .long 1023

    format_input: .asciz "%d"
    format_id_start_end_output: .asciz "%d: (%d, %d)\n"
    format_start_end_output: .asciz "(%d, %d)\n"

    format_test: .asciz "Test\n"

.text

.global main

add:
    pushl %ebp
    movl %esp, %ebp

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

add_ceil:
    incl %eax

add_skip_ceil:
    # Find free blocks
    pushl %ecx

    xorl %ecx, %ecx
    movl %eax, %edx

add_find_free_space_loop:
    pushl %eax

    movl (%edi, %ecx, 4), %eax
    cmp $0, %eax
    je add_find_continue
    jne add_no_free_block

add_find_continue:
    popl %eax

    incl %ecx
    cmp %ecx, %edx
    jne add_find_free_space_loop
    je add_found_space_for_this_file
    
add_no_free_block:
    popl %eax

    cmp storage_size, %edx
    # No free space for this file
    je add_repeat_loop

    incl %ecx
    incl %edx
    jmp add_find_free_space_loop

add_found_space_for_this_file:
    # Verify also the current index if it is free
    pushl %eax

    movl (%edi, %ecx, 4), %eax
    cmp $0, %eax
    # No free space for this file
    jne add_repeat_loop

    popl %eax

    # Calculate again the start index in %ecx
    subl %eax, %ecx
    incl %ecx

    movl file_id, %eax

    add_complete_storage_array_with_file_id:
        movl %eax, (%edi, %ecx, 4)
        incl %ecx
        cmp %ecx, %edx
    jge add_complete_storage_array_with_file_id

add_repeat_loop:
    popl %ecx
    decl %ecx
    
    jmp add_loop

add_end:
    popl %ebp
    ret

get:
    pushl $file_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx
    pushl %ebp
    movl %esp, %ebp


    xorl %ecx, %ecx

    get_search_start_index:
        movl (%edi, %ecx, 4), %edx
        incl %ecx
        cmp file_id, %edx
        jne get_search_start_index

    # %eax = start index
    movl %ecx, %eax
    decl %eax

    get_seach_end_index:
        movl (%edi, %ecx, 4), %edx
        incl %ecx
        cmp file_id, %edx
        je get_seach_end_index

    # %edx = end index
    decl %ecx
    movl %ecx, %edx

get_end:
    popl %ebp
    ret

delete:
    pushl %ebp
    movl %esp, %ebp

    call get

    # %eax = start index, %edx = end index
    movl %eax, %ecx

    delete_loop:
        movl $0, (%edi, %ecx, 4)
        incl %ecx
        cmp %edx, %ecx
        jne delete_loop

delete_end:
    popl %ebp
    ret

defragmentation:
    pushl %ebp
    movl %esp, %ebp

    # Logic:
    # Search for the end index of the first file (a)
    # Search for the start index of the second file (b)
    # If b - a > 1, move the begining of the second file to a + 1

    xorl %ecx, %ecx

defrag_loop:
    pushl %ecx
    call find_next_file
    popl %ebx

    cmp $0, %eax
    je defrag_end

    # %eax = file id
    # %ecx = start index
    # %edx = end index
    pushl %eax

    movl %edx, %ecx
    pushl %edx
    incl %ecx

    pushl %ecx
    call find_next_file
    popl %ebx

    # %ebx = end index of second file
    movl %edx, %ebx

    # %edx = end index of first file, %ecx = start index of second file
    popl %edx
    movl %ecx, %eax
    subl %edx, %eax
    # %eax = difference between end index of first file and start index of second file (number of zeros + 1)

    cmp $1, %eax
    jg defrag_move_file
    
    jmp defrag_loop

defrag_move_file:
    popl file_id
    incl %edx

    pushl %eax
    movl file_id, %eax

    defrag_move_file_left_loop:
        movl %eax, (%edi, %edx, 4)
        incl %edx
        cmp %ecx, %edx
        jne defrag_move_file_left_loop

    popl %eax

    movl %ebx, %edx
    movl %edx, %ecx
    subl %eax, %ecx
    addl $2, %ecx

    defrag_move_file_right_loop:
        movl $0, (%edi, %ecx, 4)
        incl %ecx
        cmp %edx, %ecx
        jne defrag_move_file_right_loop

    jmp defrag_loop


defrag_end:
    popl %ebp
    ret

init_storage:
    pushl %ebp
    movl %esp, %ebp

    xorl %ecx, %ecx

    init_storage_loop:
        movl $0, (%edi, %ecx, 4)
        incl %ecx
        cmp storage_size, %ecx
        jne init_storage_loop

    popl %ebp
    ret

# Used for getting next file info: %eax = file id, %ecx = start index, %edx = end index
# Input: %ecx = start index for searching
find_next_file:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %ecx

    find_next_file_start_index:
        cmp storage_size, %ecx
        je find_next_file_null

        movl (%edi, %ecx, 4), %eax
        incl %ecx
        cmp $0, %eax
        je find_next_file_start_index
        jne end

    end_search_start_index:
        decl %ecx
        # Push the start index
        pushl %ecx
        movl (%edi, %ecx, 4), %eax

    find_file_end_index:
        movl (%edi, %ecx, 4), %edx
        incl %ecx
        cmp $0, %edx
        je end_search_end_index
        jne find_file_end_index

    end_search_end_index:
        decl %ecx
        movl %ecx, %edx

    movl %eax, %ecx
    popl %eax
    jmp find_next_file_end

find_next_file_null:
    xorl %eax, %eax
    xorl %ecx, %ecx
    xorl %edx, %edx

find_next_file_end:
    popl %ebp
    ret
    
print_storage:
    xorl %ecx, %ecx

    print_storage_loop:
        pushl %ecx
        call find_next_file
        popl %ebx

        cmp $0, %eax
        je print_storage_end

        # %eax = file id
        # %ecx = start index
        # %edx = end index
        pushl %edx
        pushl %ecx
        pushl %eax
        pushl $format_id_start_end_output
        call printf
        popl %ebx
        popl %ebx
        popl %ebx
        popl %ebx

        movl %edx, %ecx

        incl %ecx
    jmp print_storage_loop

print_storage_end:
    ret

main:
    lea storage, %edi
    call init_storage

et_do_action:
    pushl $action_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    movl action_id, %eax

    cmp $1, %eax
    je et_add

    cmp $2, %eax
    je et_get

    cmp $3, %eax
    je et_delete

    cmp $4, %eax
    je et_defrag

et_add:
    pushl O
    call add
    popl %ebx

    call print_storage

    jmp et_decl_O

et_get:
    call get

    # %eax = start index, %edx = end index
    pushl %edx
    pushl %eax
    pushl $format_start_end_output
    call printf
    popl %ebx
    popl %ebx
    popl %ebx

    jmp et_decl_O

et_delete:
    call delete

    call print_storage

    jmp et_decl_O

et_defrag:
    call defragmentation

    call print_storage

    jmp et_decl_O

et_decl_O:
    decl O
    movl O, %eax

    cmp $0, %eax
    je et_exit
    jne et_do_action

et_exit:
    pushl $0
    call fflush
    popl %eax

    movl $1, %eax
    xorl %ebx, %ebx
    int $0x80





print_test:
    pushl %eax
    pushl %ebx
    pushl %ecx
    pushl %edx

    pushl $format_test
    call printf
    popl %ebx

    popl %edx
    popl %ecx
    popl %ebx
    popl %eax

    ret
