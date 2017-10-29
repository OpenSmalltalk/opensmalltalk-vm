The Cog VM source tree
---------------------
This is the README for the Git branch of Open Smalltalk VM demonstrating a MSVC 2017 15.2 x64 code generation bug:
	https://github.com/OpenSmalltalk/opensmalltalk-vm/tree/MSVCCodeGenerationBug


[![Bug report]](https://developercommunity.visualstudio.com/content/problem/62402/vc-codegenerationbug-when-compiling-smalltalk-vm.html)

As indicated in the bug report, here is how to reproduce:

  1) download this branch from github
  2) open project build.msvc/SqueakCogSpur.sln
  3) select SqueakCogSpur64 project and generate code for Debug X64
  4) inspect generated machine code

The code generated for spur64src/vm/cointerp.c line 22118:

    if ((longAt((GIV(specialObjectsOop) + BaseHeaderSize) + (((sqInt)((usqInt)(ClassArray) << (shiftForWord())))))) != ((assert(((ClassArrayCompactIndex >= 1) && (ClassArrayCompactIndex <= (classTablePageSize())))),

is incorrect, it misses the offset corresponding to `ClassArray<<shiftForWord`:

    00007FF7E55A254E mov rcx,qword ptr [rcx]
    
it should be:

    00007FF7E55A254E mov rcx,qword ptr [rcx+1A0h] 

With more context, the incorrect code is:

    00007FF7E55A2520 xor eax,eax
    00007FF7E55A2522 cmp eax,1
    00007FF7E55A2525 je $l2+271h (07FF7E55A2532h)
    00007FF7E55A2527 call classTablePageSize (07FF7E53C0752h)
    00007FF7E55A252C cmp rax,33h
    00007FF7E55A2530 jge $l2+27Fh (07FF7E55A2540h)
    00007FF7E55A2532 lea rcx,[string "((ClassArrayCompactIndex >= 1) &"... (07FF7E5684020h)]
    00007FF7E55A2539 call warning (07FF7E53C130Fh)
    00007FF7E55A253E xor eax,eax
    00007FF7E55A2540 mov rax,qword ptr [specialObjectsOop (07FF7E57A0CE8h)]
    00007FF7E55A2547 mov rcx,qword ptr [classTableFirstPage (07FF7E57A0DA8h)]
    00007FF7E55A254E mov rcx,qword ptr [rcx]
    00007FF7E55A2551 cmp qword ptr [rax+40h],rcx
    00007FF7E55A2555 je $l2+2A2h (07FF7E55A2563h)

When isolating the few lines of codes and macros into a dedicated project build.msvc/MSVCCodeGenerationBug/MSVCCodeGenerationBug.sln the code generation is correct:

    00007FF75C7D188E mov rax,qword ptr [specialObjectsOop (07FF75C7DC160h)]
    00007FF75C7D1895 mov rcx,qword ptr [classTableFirstPage (07FF75C7DC168h)]
    00007FF75C7D189C mov rcx,qword ptr [rcx+1A0h]
    00007FF75C7D18A3 cmp qword ptr [rax+40h],rcx
    00007FF75C7D18A7 je main+11Ch (07FF75C7D18BCh)
    
Nicolas Cellier (aka nice)
