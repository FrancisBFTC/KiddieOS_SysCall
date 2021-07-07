# KiddieOS SysCall (KiddieOS v1.2.5)

E um repositorio dedicado a Syscall do KiddieOS (Chamadas de sistemas) em 32 bits. Neste repositorio contem:

1. Estruturas GDT & IDT.
2. gerenciador da syscall.
3. Programas e codigo-fonte de programas do usuario.
4. Arquivos de inclusoes dos programas e do syscmng.asm

No gerenciador da syscall contem rotinas de interrupçoes de softwares que sao chamadas pelos programas KXE. Rotinas estas que sao executadas em 32 bits, logo no gerenciador e feito uma alternancia do processador antes e depois de carregar os programas na memoria. 

Obs.: Todas as Atualizaçoes referente a Syscall serao colocadas aqui. No inicio das aulas de Syscall no curso D.S.O.S os arquivos deste repositorio serao migrados para o repositorio original do KiddieOS (KiddieOS_Development).
