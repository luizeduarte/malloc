# void iniciaAlocador(): executa syscall brk para obter o endereço do topo
# da heap e o armazena em uma variável global, topoInicialHeap
iniciaAlocador:
	pushq %rbp
	movq %rsp, %rbp
	movq $12, %rax
	movq $0, %rdi
	syscall
	movq %rax, topoInicialHeap 	# como %rdi == 0, o valor atual da brk é retornando em %rax
	movq %rax, topoFinalHeap	# sem elementos, o final é igual ao começo
	popq %rbp
	ret




# void* alocaMem(int num_bytes): procura um bloco livre, Se encontrar, indica
# que o bloco está ocupado e retorna o endereço inicial do bloco. Se o novo bloco for
# maior do que o necessário, quebra ele em dois. Se não encontrar um bloco livre,
# abre espaço para um novo  usando a syscall brk, indica que o bloco está ocupado 
# e retorna o endereço inicial do bloco.
alocaMem:
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp		# aloca novo_end na pilha

	# verifica se o alocador já foi inicializado
	movq topoInicialHeap, %rax
	movq topoFinalHeap, %rbx
	cmpq %rbx, %rax
	jne alocadorInicializado
	call iniciaAlocador

    alocadorInicializado:
	pushq 16(%rbp)		# salva num_bytes na pilha
	call firstFit
	addq $8, %rsp		# desaloca num_bytes da pilha
	movq %rax, -8(%rsp)	# salva endereço inicial do bloco alocado em novo_end
	compq $-1, %rax
	jne attNo
	movq $12, %rax
	movq $0, %rdi
	syscall
	movq %rax, topoFinalHeap	# como %rdi == 0, o valor atual da brk é retornando em %rax
	movq -8(%rsp), %rax	# carrega novo_end em %rax

    attNo:
	movq $1, (%rax)		# indica que o bloco está ocupado
	movq 16(%rbp), %rbx	# carrega num_bytes em %rbx
	movq %rbx, 8(%rax)	# salva num_bytes no bloco
	addq $16, %rax		# pula o cabeçalho do bloco
	addq $8, %rsp		# desaloca novo_end da pilha
	popq %rbp
	ret





firstFit:
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp			# aloca variavel que aponta para o bloco sendo analisado
	movq topoInicialHeap, %rax	# carrega inicio da heap em %rax
	movq %rax, -8(%rbp)		# salva o começo da heap na variavel local	
	movq topoFinalHeap, %rbx	# carrega fim da heap em %rbx

    verificaFim:			# verifica se ja chegou no fim da heap
	comp %rbx, %rax
	jg semBlocos			# se topoFinalHeap < topoInicialHeap, não há blocos alocados mais
					# se não, verifica se o bloco atual está livre

    verificaBloco:			# verifica se o bloco está livre
	movq (%rax), %rbx		# carrega informação gerencial do bloco em %rbx
	cmpq $0, %rbx
	je verificaTamanho		# se está livre, verifica se o tamanho basta, se não, passa para o proximo bloco
	movq 8(%rax), %rbx		# carrega tamanho do bloco em %rbx
	addq $16, %rbx
	addq %rbx, %rax			# pula para o proximo bloco
	jmp verificaFim			# reinicia o loop de verificação


    verificaTamanho:			# verifica se o bloco é grande o suficiente
	movq 8(%rax), %rbx		# carrega tamanho do bloco sendo analisado em %rbx
	movq 16(%rbp), %rcx		# carrega tamanho do bloco a ser alocado (passado por parametro) em %rcx
	cmpq %rcx, %rbx			# compara tamanho do bloco sendo analisado com o tamanho do bloco a ser alocado
	jge blocoLivre		
	addq $16, %rbx			# se o bloco não é grande o suficiente, pula para o proximo bloco
	addq %rbx, %rax
	jmp verificaFim			# reinicia loop



    semBlocos:
	movq $-1, %rax	//MUDAR ESTRATÉGIA


    blocoLivre:
	addq $8, %rsp		# desaloca variavel que aponta para o bloco sendo lido
	popq %rbp
	ret





# void finalizaAlocador() Executa syscall brk para restaurar o valor original da heap contido em topoInicialHeap
finalizaAlocador:
	pushq %rbp
	movq %rsp, %rbp
	movq topoInicialHeap, %rdi
	movq $12, %rax
	syscall		# brk == topoInicialHeap	
	popq %rbp
	ret





# int liberaMem(void* bloco) indica que o bloco está livre.
liberaMem:
	pushq %rbp
	movq %rsp, %rbp
	movq 16(%rbp), %rax	# carrega bloco em %rax
	subq $16, %rax		# volta para o cabeçalho do bloco
	movq $0, (%rax)		# indica que o bloco está livre
    fusaoNos:
	movq topoInicialHeap, %rax 	# carrega o inicio da heap para %rax
	
    comparaPrimeiro:	
	compq $0, %rax
	jne else

    else:	# bloco nao esta livre
	movq 8(%rax), %rbx	# carrega o tamanho do bloco em %rbx
	addq $16, %rax
	addq %rbx %rax























.section .text
imprimeParte:
    pushq       %rbp                    # Empilha endereco-base do registro de ativacao antigo
    movq        %rsp, %rbp              # Atualiza ponteiro para endereco-base do registro de ativacao atual
    movq        $0, %rax                # Inicializa contador em 0
    pushq       %rax                    # Aloca variavel local (contador)
  for:
    movq        -8(%rbp), %rax          # Obtem contador
    movq        %rsi, %rbx              # Obtem segundo parametro
    cmpq        %rax, %rbx              # Compara segundo parametro com contador
    jle         done_for                # Se ja foram feitas as impressoes requisitadas, desvia para o final do for
    pushq       %rdi                    # Caller save do primeiro parametro
    pushq       %rsi                    # Caller save do segundo parametro
    call        putchar                 # Chama funcao para imprimir caractere do primeiro parametro
    popq        %rsi                    # Restaura segundo parametro
    popq        %rdi                    # Restaura primeiro parametro
    movq        -8(%rbp), %rax          # Obtem contador
    addq        $1, %rax                # Incrementa contador
    movq        %rax, -8(%rbp)          # Atualiza contador
    jmp         for                     # Desvia para o inicio do for
  done_for:
    addq        $8, %rsp                # Desempilha variavel local
    popq        %rbp                    # Desmonta registro de ativacao atual e restaura ponteiro para o antigo
    ret                                 # Retorna
.globl imprMapa
imprMapa:
    pushq       %rbp                    # Empilha endereco-base do registro de ativacao antigo
    movq        %rsp, %rbp              # Atualiza ponteiro para endereco-base do registro de ativacao atual
    call        brkGet                  # Obtem ponteiro para final da heap
    pushq       %rax                    # Empilha variavel local apontando para final da heap
    movq        topoInicialHeap, %rbx   # Obtem ponteiro para inicio da heap
    pushq       %rbx                    # Empilha variavel local apontando para inicio da heap
    pushq       %rax                    # Empilha variavel local apontando para final da heap
  loop:
    movq        -16(%rbp), %rax         # Obtem ponteiro para informacao gerencial
    movq        -8(%rbp), %rbx          # Obtem ponteiro para final da heap
    cmpq        %rax, %rbx              # Compara final da heap com informacao gerencial atual
    jle         done_loop               # Se todos os blocos foram percorridos, desvia para o final do loop
    movq        $35, %rdi               # Estabelece primeiro parametro ('#')
    movq        $16, %rsi               # Estabelece segundo parametro (16 - numero de bytes de informacao gerencial)
    call        imprimeParte            # Chama funcao para imprimir bytes da informacao gerencial
    movq        -16(%rbp), %rax         # Obtem ponteiro para informacao gerencial
    movq        %rax, %rsi              # Obtem ponteiro para informacao gerencial
    movq        8(%rsi), %rsi           # Obtem tamanho do bloco (segundo parametro)
    movq        (%rax), %rax            # Obtem informacao gerencial
    movq        $0, %rbx                # Obtem valor que indica bloco livre
    cmpq        %rax, %rbx              # Verifica se informacao gerencial indica bloco livre
    je          else                    # Se sim, desvia para else
    movq        $43, %rdi               # Estabelece primeiro parametro ('+' - bloco ocupado)
    jmp         done_if                 # Desvia para final do if
  else:
    movq        $45, %rdi               # Estabelece primeiro parametro ('-' - bloco livre)
  done_if:
    call        imprimeParte            # Chama funcao para imprimir bytes do bloco
    movq        -16(%rbp), %rax         # Obtem ponteiro para informacao gerencial
    movq        8(%rax), %rbx           # Obtem tamanho do bloco
    addq        $16, %rbx               # Obtem tamanho do bloco + informacao gerencial
    addq        %rax, %rbx              # Obtem ponteiro para proxima informacao gerencial
    movq        %rbx, -16(%rbp)         # Atualiza variavel local
    jmp         loop                    # Desvia para inicio do loop
  done_loop:
    movq        $10, %rdi               # Estabelece parametro ('\n' - newline)
    call        putchar                 # Imprime newline '\n'
    popq        %rdi                    # Desempilha variavel local com topo da heap usa como parametro
    call        brkUpdate               # Restaura topo da heap (problema com o putchar)
    addq        $16, %rsp               # Desempilha variaveis locais
    popq        %rbp                    # Desmonta registro de ativacao atual e restaura ponteiro para o antigo
    ret                                 # Retorna