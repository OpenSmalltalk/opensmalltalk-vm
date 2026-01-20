REM The last version of clang to support 32-bit x86 is version 12.
REM Install it in C:\LLVM12-32. This is better than C:\Program Files\LLVM12-32
REM because the space in Program Files can confuse configure programs (e.g. x264's)
set PATH=%PATH%;c:\cygwin64\bin;c:\LLVM12-32\bin
