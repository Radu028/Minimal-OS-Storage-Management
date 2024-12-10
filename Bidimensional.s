.data
    O: .space 4
    N: .space 4
    file_id: .space 4
    file_dimension: .space 4
    action_id: .space 4

    find_file_id: .space 4
    find_file_row_start: .space 4
    find_file_row_end: .space 4
    find_file_col_start: .space 4
    find_file_col_end: .space 4
    find_file_start_index: .space 4
    find_file_end_index: .space 4

    add_blocks: .space 4
    add_row: .space 4

    storage: .space 1024
    storage_size: .long 1024
    rows: .long 32
    cols: .long 32

    format_input: .asciz "%d"
    format_id_start_end_output: .asciz "%d: ((%d, %d), (%d, %d))\n"
    format_start_end_output: .asciz "((%d, %d), (%d, %d))\n"

    format_test: .asciz "Test\n"
    format_test_nr: .asciz "Test %d\n"

.text

.global main

# %eax = index
calc_index:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = row
    # 12(%ebp) = col

    pushl %edx
    xorl %edx, %edx

    movl 8(%ebp), %eax
    mull cols
    addl 12(%ebp), %eax

    popl %edx

    popl %ebp
    ret

# %eax = row (from 0 to rows - 1) and %edx = col (from 0 to cols - 1)
calc_position:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = index

    movl 8(%ebp), %eax
    xorl %edx, %edx

    movl cols, %ecx
    divl %ecx

    popl %ebp
    ret

init_storage:
    movl rows, %eax
    mull cols
    decl %eax
    xorl %ecx, %ecx

    init_storage_loop:
        movb $0, (%edi, %ecx, 1)
        incl %ecx
        cmp %eax, %ecx
        jle init_storage_loop

    ret

find_next_file:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = index

    movl $0, find_file_id
    movl $0, find_file_row_start
    movl $0, find_file_row_end
    movl $0, find_file_col_start
    movl $0, find_file_col_end

    xorl %eax, %eax
    movl 8(%ebp), %ecx

    find_next_file_start_index:
        cmp storage_size, %ecx
        je find_next_file_end

        movb (%edi, %ecx, 1), %al
        incl %ecx
        cmp $0, %al
        je find_next_file_start_index

    end_search_start_index:
        movl %eax, find_file_id

        decl %ecx
        pushl %ecx
        call calc_position
        popl %ecx

        movl %ecx, find_file_start_index
        movl %eax, find_file_row_start
        movl %edx, find_file_col_start

        xorl %eax, %eax

    find_file_end_index:
        movb (%edi, %ecx, 1), %al
        incl %ecx
        cmp find_file_id, %al
        je find_file_end_index

    end_search_end_index:
        subl $2, %ecx
        pushl %ecx
        call calc_position
        popl %ecx

        movl %ecx, find_file_end_index
        movl %eax, find_file_row_end
        movl %edx, find_file_col_end

find_next_file_end:
    popl %ebp
    ret

print_storage:
    xorl %ecx, %ecx

    print_storage_loop:
        pushl %ecx
        call find_next_file
        popl %ebx

        movl find_file_id, %eax
        cmp $0, %eax
        je print_storage_end

        pushl find_file_col_end
        pushl find_file_row_end
        pushl find_file_col_start
        pushl find_file_row_start
        pushl find_file_id
        pushl $format_id_start_end_output
        call printf
        popl %ebx
        popl %ebx
        popl %ebx
        popl %ebx
        popl %ebx
        popl %ebx

        # Calculate the next index
        pushl find_file_col_end
        pushl find_file_row_end
        call calc_index
        popl %ebx
        popl %ebx

        movl %eax, %ecx
        incl %ecx

    jmp print_storage_loop


print_storage_end:
    ret

add:
    pushl %ebp
    movl %esp, %ebp

    # File id = 8(%ebp)
    # File dimension = 12(%ebp)

    # Calculate the blocks needed in %eax
    movl 12(%ebp), %eax
    xorl %edx, %edx
    movl $8, %ecx
    divl %ecx

    movl $0, add_row
    
    # Ceil for %eax if it is the case, if not skip
    cmp $0, %edx
    je add_skip_ceil

    incl %eax

add_skip_ceil:
    movl %eax, add_blocks

    # Find free blocks
    xorl %ecx, %ecx
    movl %eax, %edx

    # %edx = end index for the current file (for first line)
    decl %edx
    cmp storage_size, %edx
    jge add_end

    xorl %eax, %eax
add_find_free_space_loop:
    movb (%edi, %ecx, 1), %al
    cmp $0, %al
    jne add_no_free_block

    incl %ecx
    cmp %ecx, %edx
    jge add_find_free_space_loop

    jmp add_found_space_for_this_file

add_no_free_block:
    incl %edx
    movl %edx, %eax

    pushl %edx
    xorl %edx, %edx

    movl cols, %ecx
    divl %ecx

    cmp $0, %edx
    je add_no_free_block_next_line_pop

    popl %edx
    # Recalculate the start index in %ecx
    movl %edx, %ecx
    incl %ecx
    subl add_blocks, %ecx
    jmp add_find_free_space_loop

add_no_free_block_next_line_pop:
    popl %edx

    incl add_row
    movl add_row, %edx
    cmp rows, %edx
    jge add_end

    # Recalculate the end index in %edx
    pushl add_blocks
    pushl add_row
    call calc_index
    popl %ebx
    popl %ebx

    movl %eax, %edx
    decl %edx

    jmp add_find_free_space_loop

add_found_space_for_this_file:
    # Calculate again the start index in %ecx
    subl add_blocks, %ecx

    # Write the file in the storage
    movl 8(%ebp), %eax

    add_found_space_for_this_file_loop:
        movb %al, (%edi, %ecx, 1)
        incl %ecx
        cmp %ecx, %edx
        jge add_found_space_for_this_file_loop

add_end:
    popl %ebp
    ret

get:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = file_id

    movl 8(%ebp), %eax

    movl $0, find_file_row_start
    movl $0, find_file_row_end
    movl $0, find_file_col_start
    movl $0, find_file_col_end

    movl $0, find_file_start_index
    movl $0, find_file_end_index

    xorl %ecx, %ecx
    xorl %edx, %edx

    get_find_file_start_index:
        cmp storage_size, %ecx
        je get_end

        movb (%edi, %ecx, 1), %dl
        incl %ecx
        cmp %al, %dl
        jne get_find_file_start_index

    get_end_search_start_index:
        decl %ecx
        pushl %ecx
        call calc_position
        popl %ecx

        movl %ecx, find_file_start_index

        movl %eax, find_file_row_start
        movl %edx, find_file_col_start

        movl 8(%ebp), %eax
        xorl %edx, %edx

    get_find_file_end_index:
        movb (%edi, %ecx, 1), %dl
        incl %ecx
        cmp %al, %dl
        je get_find_file_end_index

    get_end_search_end_index:
        subl $2, %ecx
        pushl %ecx
        call calc_position
        popl %ecx

        movl %ecx, find_file_end_index

        movl %eax, find_file_row_end
        movl %edx, find_file_col_end

get_end:
    popl %ebp
    ret

delete:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = file_id

    movl 8(%ebp), %eax

    pushl %eax
    call get
    popl %ebx

    movl find_file_start_index, %ecx

    # STIU SIGUR CA PRIMESC UN FISIER EXISTENT?
    delete_loop:
        movb $0, (%edi, %ecx, 1)
        incl %ecx
        cmp find_file_end_index, %ecx
        jle delete_loop

    popl %ebp
    ret

defragmentation:
    xorl %ecx, %ecx

    defragmentation_loop:
        pushl %ecx
        call find_next_file
        popl %ecx

        movl find_file_id, %eax
        cmp $0, %eax
        je defragmentation_end

        pushl find_file_row_start
        pushl find_file_end_index
        movl find_file_end_index, %ecx
        incl %ecx

        pushl %ecx
        call find_next_file
        popl %ecx

        movl find_file_id, %eax
        cmp $0, %eax
        je defragmentation_end_pop

        # %edx = end index of first file
        popl %edx
        movl find_file_start_index, %eax
        decl %eax
        subl %edx, %eax
        # %eax = difference between end index of first file and start index of second file (number of zeros + 1)

        # %ecx = row index of the first file
        popl %ecx

        cmp $1, %eax
        je defragmentation_loop

        # Check if the second file is on the same row and can be moved a few columns to the left
        # OR
        # Check if it is on the next row and can be moved to the current row
        # OR
        # Check if it is on the next row and cannot be moved to the current row, but can be moved a few columns to the left

        cmp find_file_row_start, %ecx
        je defragmentation_same_row
        jl defragmentation_next_row

    defragmentation_same_row:
        # Move the second file to the left
        incl %edx
        movl %edx, %ecx

        pushl %eax
        movl find_file_id, %eax

        # Fill the space between the two files with second file's id
        defragmentation_move_file_left_loop:
            movb %al, (%edi, %ecx, 1)
            incl %ecx
            # TODO: Calculate the end index of the moved file
            cmp find_file_start_index, %ecx
            jne defragmentation_move_file_left_loop

        popl %eax
        movl find_file_end_index, %ecx
        subl %eax, %ecx
        addl $2, %ecx

        # Empty the space after the second file
        defragmentation_move_file_right_loop:
            movb $0, (%edi, %ecx, 1)
            incl %ecx
            cmp find_file_end_index, %ecx
            jle defragmentation_move_file_right_loop

        jmp defragmentation_loop

    defragmentation_next_row:
        # Calculate second file's size in %ecx
        movl find_file_start_index, %eax
        movl find_file_end_index, %ecx
        subl %eax, %ecx
        incl %ecx

        pushl %edx

        # Calculate the end column index of first file in %eax
        # movl %edx, %eax
        # incl %eax
        # xorl %edx, %edx
        # movl cols, %ecx
        # divl %ecx

        # Or use find_file_col_end
        movl find_file_col_end, %eax
        incl %eax
        movl cols, %edx
        subl %eax, %edx # %edx = number of columns free in the current row

        popl %eax # %eax = end index of first file

        cmp %ecx, %edx
        jl defragmentation_next_row_check_next_row

        # Move the second file to the current row
        
        movl %ecx, %edx # %edx = Second file's size
        movl %eax, %ecx # %ecx = First file's end index
        addl %eax, %edx # %edx = End index of the second file (new position)

        movl %eax, %edx
        movl find_file_id, %eax

        defragmentation_next_row_move_file_to_current_row_loop:
            movb %al, (%edi, %ecx, 1)
            incl %ecx
            cmp %ecx, %edx
            jge defragmentation_next_row_move_file_to_current_row_loop

        movl find_file_start_index, %ecx
        movl find_file_end_index, %edx

        defragmentation_next_row_empty_space_after_second_file_loop:
            movb $0, (%edi, %ecx, 1)
            incl %ecx
            cmp %ecx, %edx
            jge defragmentation_next_row_empty_space_after_second_file_loop

        jmp defragmentation_loop

    defragmentation_next_row_check_next_row:
        movl find_file_col_start, %eax

        cmp $0, %eax
        je defragmentation_loop_continue

        movl find_file_row_start, %eax
        movl cols, %ecx
        mull %ecx
        movl %edx, %ecx

        movl find_file_id, %eax

        defragmentation_next_row_check_next_row_left_loop:
            movb %al, (%edi, %ecx, 1)
            incl %ecx
            cmp find_file_start_index, %ecx
            jne defragmentation_next_row_check_next_row_left_loop

        movl find_file_col_end, %ecx
        subl find_file_col_start, %ecx
        addl $2, %ecx

    defragmentation_loop_continue:
        movl find_file_end_index, %ecx
        incl %ecx

        jmp defragmentation_loop

        
        
defragmentation_end_pop:
    # Free the stack from the first file's indexes
    popl %eax
    popl %eax

defragmentation_end:
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

    cmp $1, %eax
    je et_add

    cmp $2, %eax
    je et_get

    cmp $3, %eax
    je et_delete

    cmp $4, %eax
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
        pushl file_id
        call add
        popl %ebx
        popl %ebx

        decl N
        movl N, %ecx

        cmp $0, %ecx
        jne et_add_loop


    call print_storage

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

    pushl find_file_col_end
    pushl find_file_row_end
    pushl find_file_col_start
    pushl find_file_row_start
    pushl $format_start_end_output
    call printf
    popl %ebx
    popl %ebx
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
    # call defragmentation

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

test_print:
    pushl %eax
    pushl %ebx
    pushl %ecx
    pushl %edx

    pushl $format_test
    call printf

    popl %edx
    popl %ecx
    popl %ebx
    popl %eax

    ret

test_print_nr:
    pushl %ebp
    movl %esp, %ebp

    pushl %eax
    pushl %ebx
    pushl %ecx
    pushl %edx

    movl 8(%ebp), %eax
    pushl %eax
    pushl $format_test_nr
    call printf
    popl %ebx
    popl %ebx

    popl %edx
    popl %ecx
    popl %ebx
    popl %eax

    popl %ebp
    ret
    
