.section .text

global iniciaAlocador
global liberaMem
global alocaMem
global imprimeMem

%macro FUNCTION_PROTOTYPE 1
    global %1
    %1:
    ret
%endmacro

FUNCTION_PROTOTYPE iniciaAlocador
FUNCTION_PROTOTYPE liberaMem
FUNCTION_PROTOTYPE alocaMem
FUNCTION_PROTOTYPE imprimeMem
