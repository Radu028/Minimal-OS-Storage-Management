.section .note.GNU-stack,"",@progbits
.data
    O: .space 4
    N: .space 4
    file_id: .space 4
    file_dimension: .space 4
    action_id: .space 4

    storage: .space 1024
    storage_size: .long 1024

    format_input: .asciz "%d"
    format_id_start_end_output: .asciz "%d: (%d, %d)\n"
    format_start_end_output: .asciz "(%d, %d)\n"

.text

.global main

get_blocks_needed:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax
    xorl %edx, %edx
    movl $8, %ecx
    divl %ecx

    cmpl $0, %edx
    je get_blocks_needed_skip_ceil

    incl %eax

get_blocks_needed_skip_ceil:
    popl %ebp
    ret

add:
    pushl %ebp
    movl %esp, %ebp

    # File id = 8(%ebp)
    # File dimension in blocks = 12(%ebp)

    # Check if the file descriptor is valid
    movl 8(%ebp), %eax
    cmpl $0, %eax
    jl add_end

    # Check if the file already exists
    pushl %eax
    call get
    popl %ecx

    cmpl $0, %eax
    jne add_end

    # Find free blocks
    movl 12(%ebp), %edx

    # %edx = end index for the current file
    decl %edx
    cmpl storage_size, %edx
    jge add_no_space_for_file

    xorl %ecx, %ecx
    xorl %eax, %eax

add_find_free_space_loop:
    movb (%edi, %ecx, 1), %al
    cmpb $0, %al
    jne add_no_free_block

    incl %ecx
    cmpl %ecx, %edx
    jge add_find_free_space_loop

    jmp add_found_space_for_this_file

add_no_free_block:
    incl %edx

    cmpl storage_size, %edx
    # No free space for this file
    je add_no_space_for_file

    # Recalculate the start index in %ecx
    movl %edx, %ecx
    incl %ecx
    subl 12(%ebp), %ecx

    jmp add_find_free_space_loop

add_found_space_for_this_file:
    # Calculate again the start index in %ecx
    subl 12(%ebp), %ecx
    movl 8(%ebp), %eax

    add_fill_storage_array_with_file_id:
        movb %al, (%edi, %ecx, 1)
        incl %ecx
        cmpl %ecx, %edx
    jge add_fill_storage_array_with_file_id

    subl 12(%ebp), %ecx

    # Print the file id and the start and end index
    pushl %edx
    pushl %ecx
    pushl %eax
    pushl $format_id_start_end_output
    call printf
    popl %eax
    popl %eax
    popl %ecx
    popl %edx

    jmp add_end

add_no_space_for_file:
    # No space for this file so print "fileId: (0, 0)"
    movl 8(%ebp), %eax
    xorl %ecx, %ecx

    pushl %ecx
    pushl %ecx
    pushl %eax
    pushl $format_id_start_end_output
    call printf
    popl %eax
    popl %eax
    popl %ecx
    popl %ecx

add_end:
    popl %ebp
    ret

get:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax
    movl %eax, file_id

    xorl %ecx, %ecx
    xorl %edx, %edx

    get_search_start_index:
        cmpl storage_size, %ecx
        je get_null

        movb (%edi, %ecx, 1), %dl
        incl %ecx
        cmpb %al, %dl
        jne get_search_start_index

    # %eax = start index
    movl %ecx, %esi
    decl %esi

    get_seach_end_index:
        movb (%edi, %ecx, 1), %dl
        incl %ecx
        cmpb %al, %dl
        je get_seach_end_index

    # %edx = end index
    subl $2, %ecx
    movl %ecx, %edx
    movl %esi, %eax

    jmp get_end

get_null:
    xorl %eax, %eax
    xorl %edx, %edx

get_end:
    popl %ebp
    ret

delete:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax

    pushl %eax
    call get
    popl %ebx

    cmpl $0, %edx
    je delete_end

    # %eax = start index, %edx = end index
    movl %eax, %ecx

    delete_loop:
        movb $0, (%edi, %ecx, 1)
        incl %ecx
        cmpl %ecx, %edx
        jge delete_loop

delete_end:
    popl %ebp
    ret

defragmentation:
    # Logic:
    # Search for the end index of the first file (a)
    # Search for the start index of the second file (b)
    # If b - a > 1, move the begining of the second file to a + 1

    xorl %ecx, %ecx

    pushl %ecx
    call find_next_file
    popl %esi

    cmpl $0, %eax
    je defrag_end

    cmpl $0, %ecx
    je defrag_continue_to_loop

    # Move all files to the start
    pushl %edx
    subl %ecx, %edx

    xorl %ecx, %ecx
    defrag_from_start_fill_loop:
        movb %al, (%edi, %ecx, 1)
        incl %ecx
        cmpl %ecx, %edx
        jge defrag_from_start_fill_loop

    popl %edx
    defrag_from_start_empty_loop:
        movb $0, (%edi, %ecx, 1)
        incl %ecx
        cmpl %ecx, %edx
        jge defrag_from_start_empty_loop

    defrag_continue_to_loop:
        xorl %ecx, %ecx

    defrag_loop:
        pushl %ecx
        call find_next_file # %eax = file id, %ecx = start index, %edx = end index
        popl %esi

        # If there is no first file, end the defragmentation
        cmpl $0, %eax
        je defrag_end

        movl %edx, %esi
        incl %edx

        pushl %edx
        call find_next_file
        popl %ebx

        # If there is no second file, end the defragmentation
        cmpl $0, %eax
        je defrag_end

        movl %eax, file_id

        # Calc in %eax difference between end index of first file and start index of second file (number of zeros + 1)
        movl %ecx, %eax
        subl %esi, %eax

        cmpl $1, %eax
        je defrag_loop

    defrag_move_file:
        pushl %edx

        subl %ecx, %edx
        incl %edx
        addl %esi, %edx

        movl %esi, %ecx
        incl %ecx

        movl file_id, %eax

        # Fill the space between the two files with second file's id
        defrag_move_file_left_loop:
            movb %al, (%edi, %ecx, 1)
            incl %ecx
            cmpl %ecx, %edx
            jge defrag_move_file_left_loop

        popl %edx
        defrag_move_file_right_loop:
            movb $0, (%edi, %ecx, 1)
            incl %ecx
            cmpl %ecx, %edx
            jge defrag_move_file_right_loop

        movl %esi, %ecx
        incl %ecx

        jmp defrag_loop

defrag_end:
    ret

init_storage:
    xorl %ecx, %ecx

    init_storage_loop:
        movb $0, (%edi, %ecx, 1)

        incl %ecx
        cmpl storage_size, %ecx
        jne init_storage_loop

    ret

# Used for getting next file info: %eax = file id, %ecx = start index, %edx = end index
# Input: %ecx = start index for searching
find_next_file:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %ecx
    xorl %eax, %eax

    find_next_file_start_index:
        cmpl storage_size, %ecx
        jge find_next_file_null

        movb (%edi, %ecx, 1), %al
        incl %ecx
        cmpb $0, %al
        je find_next_file_start_index

    # Push the start index
    pushl %ecx

    find_file_end_index:
        movb (%edi, %ecx, 1), %ah
        incl %ecx
        cmpb %al, %ah
        je find_file_end_index

    movb $0, %ah
    subl $2, %ecx
    movl %ecx, %edx

    popl %ecx
    decl %ecx
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

        cmpl $0, %eax
        je print_storage_end

        pushl %edx # end index
        pushl %ecx # start index
        pushl %eax # file id
        pushl $format_id_start_end_output
        call printf
        popl %ebx
        popl %eax
        popl %ecx
        popl %edx

        movl %edx, %ecx
        incl %ecx
    jmp print_storage_loop

print_storage_end:
    ret

main:
    lea storage, %edi
    call init_storage

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

    movl action_id, %eax

    cmpb $1, %al
    je et_add

    cmpb $2, %al
    je et_get

    cmpb $3, %al
    je et_delete

    cmpb $4, %al
    je et_defrag

et_add:
    pushl $N
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    et_add_loop:
        pushl $file_id
        pushl $format_input
        call scanf
        popl %ebx
        popl %ebx

        pushl $file_dimension
        pushl $format_input
        call scanf
        popl %ebx
        popl %ebx

        pushl file_dimension
        call get_blocks_needed
        popl %ebx

        # Skip adding file if the dimension is not 2 blocks at least
        cmpl $2, %eax
        jl et_add_skip

        pushl %eax
        pushl file_id
        call add
        popl %ebx
        popl %ebx
    
    et_add_skip:
        decl N
        movl N, %ecx

        cmpl $0, %ecx
        jne et_add_loop


    jmp et_decl_O

et_get:
    pushl $file_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    pushl file_id
    call get
    popl %ebx

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
    pushl $file_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    pushl file_id
    call delete
    popl %ebx

    call print_storage

    jmp et_decl_O

et_defrag:
    call defragmentation

    call print_storage

    jmp et_decl_O

et_decl_O:
    decl O
    movl O, %eax

    cmpl $0, %eax
    je et_exit
    jne et_do_action

et_exit:
    pushl $0
    call fflush
    popl %eax

    movl $1, %eax
    xorl %ebx, %ebx
    int $0x80
