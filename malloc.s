.section .data
	topoInicialHeap: .quad 0
	topoFinalHeap: .quad 0
	
.section .text

.globl iniciaAlocador
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



.globl alocaMem
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
	cmpq $0, %rax
	jne alocadorInicializado
	call iniciaAlocador

    alocadorInicializado:
	pushq %rdi		# salva num_bytes na pilha
	call firstFit
	popq %rdi		# desaloca num_bytes da pilha
	cmpq $0, %rax		# verifica se existe bloco disponível
	jne attNo

    addHeap:			# adiciona um novo bloco
	movq %rdi, %rcx
	addq $16, %rcx
	pushq %rdi
	movq $12, %rax
	movq %rcx, %rdi
	syscall
	popq %rdi
	movq %rax, topoFinalHeap	# atuzaliza topoFinalHeap
	subq %rax, %rcx
	movq %rax, -8(%rbp)		# salva o novo endereço na variável local

    attNo:
	movq $1, (%rax)		# indica que o bloco está ocupado
	movq %rdi, %rbx		# carrega num_bytes em %rbx
	movq %rbx, 8(%rax)	# salva num_bytes no bloco
	movq -8(%rbp), %rax	# retorna o endereço inicial do bloco
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

    # iniciando loop do while (enquanto não encontra um espaço adequado)
    verificaFim:			# if que verifica se não chegou no fim da heap
	cmpq %rbx, %rax
	jg semBlocos			# se topoFinalHeap < topoInicialHeap, não há blocos alocados mais
					# se não, verifica se o bloco atual está livre

    verificaBloco:			# if que verifica se o bloco está livre
	movq (%rax), %rbx		# carrega informação gerencial do bloco em %rbx
	cmpq $0, %rbx
	jne proxBloco			# se não está livre, passa para o proximo bloco, se não, verifica o tamanho

    verificaTamanho:			# if para verificar se o bloco é grande o suficiente
	movq 8(%rax), %rbx		# carrega tamanho do bloco sendo analisado em %rbx
	movq %rdi, %rcx		# carrega tamanho do bloco a ser alocado (passado por parametro) em %rcx
	cmpq %rcx, %rbx			# compara tamanho do bloco sendo analisado com o tamanho do bloco a ser alocado
	jge blocoLivre			# se o bloco a ser alocado for maior, passa para o proximo bloco

    proxBloco:				# pula para o proximo bloco
	movq 8(%rax), %rbx		# carrega tamanho do bloco sendo analisado em %rbx
	addq $16, %rbx			
	addq %rbx, %rax			# %rax recebe novo endereço
	jmp verificaFim			
    # fim loop do while


    semBlocos:
	movq $0, %rax
	jmp retFirstFit

    blocoLivre:				# TODO: talvez trocar a ordem melhore a questão do %rax ser mudado antes do cmpq
	movq %rdi, %rbx		# carrega tamanho do bloco a ser alocado (passado por parametro) em %rbx
	addq $16, %rax			# rax recebe possível novo endereço
	cmpq %rbx, -8(%rax)		# verifica se o tamanho é exatamente igual
	je retFirstFit
	addq $16, %rbx			# se o bloco livre for maior que o novo bloco + 16, split
	cmpq %rbx, -8(%rax)		# compara tamanho do bloco livre com o tamanho do bloco a ser alocado
	# jge split			# se o bloco livre for maior, split
	# se nao, ver o que faz

    retFirstFit:
	popq %rbp
	ret



.globl finalizaAlocador
# void finalizaAlocador() executa syscall brk para restaurar o valor original da heap contido em topoInicialHeap
finalizaAlocador:
	pushq %rbp
	movq %rsp, %rbp
	movq topoInicialHeap, %rdi
	movq $0, topoInicialHeap
	movq $0, topoFinalHeap
	movq $12, %rax
	syscall		# brk == topoInicialHeap	
	popq %rbp
	ret




.globl liberaMem
# int liberaMem(void* bloco) indica que o bloco está livre.
liberaMem:
	pushq %rbp
	movq %rsp, %rbp
	movq %rdi, %rax	# carrega bloco em %rax
	subq $16, %rax		# volta para o cabeçalho do bloco
	movq $0, (%rax)		# indica que o bloco está livre
	popq %rbp
	ret


.globl imprimeMapa
imprimeMapa:
	pushq %rbp
	movq %rsp, %rbp

	subq $8, %rsp				# aloca espaço para variável local
	movq topoInicialHeap, %r9		# armazena valor do inicio da heap
	movq topoFinalHeap, %r10		# armazena valor do fim da heap
	movq %r9, -8(%rbp)			# salva o inicio da heap na variavel local

    veriricaFimHeap:
	cmpq -8(%rbp), %r10		# verifica se o ponteiro (variável local) chegou ao fim da heap
	jge fimHeap
	movq $STR_GERENCIAL, %rsi 	# início do buffer 
	movq $16, %rdx			# tam do buffer
	movq $1, %rax			# código do comando syscall write
	movq $1, %rdi			# stdout
	syscall				# syscall write

	movq -8(%rbp), %rbx		# carrega ponteiro em rbx
	movq 8(%rbx), %rcx		# carrega tamanho do bloco em rcx
	movq (%rbx), %rbx		# pega o bit de ocupacao do bloco
	movq $0, %r8			# inicializa contador de bytes impressos em r8

    verificaFimBloco:
	cmpq %rcx, %r8			# verifica se o contador de bytes impressos é igual ao tamanho do bloco
	jge fimBloco
	movq $1, %rdi			# argumentos para o syscall write
	movq $1, %rdx
	movq $1, %rax

	cmpq $0, %rbx			# se 0 imprime a string BYTE_LIVRE, se 1 imprime BYTE_OCUPADO
	jne imprimeOcupado
	movq $BYTE_LIVRE, %rsi		# imprime BYTE_LIVRE "-"
	jmp byteImpresso		
    imprimeOcupado:
	movq $BYTE_OCUPADO, %rsi	# imprime BYTE_OCUPADO "+"

    byteImpresso:
	syscall
	addq $1, %r8			# atualiza contador de bytes impressos
	jmp verificaFimHeap		# volta a verififcar se ainda restam blocos para imprimir

    fimBloco:
	addq 16, -8(%rbp)
	addq %rcx, -8(%rbp)		# atualiza ponteiro para o próximo bloco
	jmp while_bloco

    fimHeap:
	movq $1, %rdx 			# argumentos para o syscall write 
	movq $1, %rax
	movq $1, %rdi
	syscall

	addq $8, %rsp
	popq %rbp
	ret