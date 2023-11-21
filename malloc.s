.section .data
	topoInicialHeap: .quad 0
	topoFinalHeap: .quad 0
	STR_GERENCIAL: .string "################"
	BYTE_LIVRE: .byte '-'
	BYTE_OCUPADO: .byte '+'
	NOVA_LINHA: .byte '\n'
	
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
	pushq %rdi
	addq $16, %rdi		# adiciona 16 bytes ao tamanho do bloco
	addq topoFinalHeap, %rdi
	movq $12, %rax		# codigo da syscall brk
	syscall
	popq %rdi
	movq topoFinalHeap, %rax
	addq $16, topoFinalHeap		# atualizando topoFinalHeap
	addq %rdi, topoFinalHeap

    attNo:
	movq $1, (%rax)		# indica que o bloco está ocupado
	movq %rdi, 8(%rax)	# salva num_bytes no bloco
	addq $16, %rax		# retorna ponteiro para o conteúdo
	addq $8, %rsp		# desaloca novo_end da pilha
	popq %rbp
	ret





firstFit:
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp			# aloca variavel que aponta para o bloco sendo analisado
	movq topoInicialHeap, %rax	# carrega inicio da heap em %rax
	movq %rax, -8(%rbp)		# salva o começo da heap na variavel local	

    # iniciando loop do while (enquanto não encontra um espaço adequado)
    verificaFim:			# if que verifica se não chegou no fim da heap
	cmpq topoFinalHeap, %rax
	jge semBlocos			# se topoFinalHeap <= topoInicialHeap, não há blocos alocados mais
						# se não, verifica se o bloco atual está livre

    # verifica se o bloco está livre
	cmpq $0, (%rax)
	jne proxBloco			# se não está livre, passa para o proximo bloco, se não, verifica o tamanho

    # verifica se o bloco é grande o suficiente
	cmpq %rdi, 8(%rax)			# compara tamanho do bloco sendo analisado com o tamanho do bloco a ser alocado
	jge verificaSplit			# se o bloco possui tamanho suficiente, verifica se é necessário o split

    proxBloco:				# pula para o proximo bloco
	movq 8(%rax), %rbx		# carrega tamanho do bloco sendo analisado em %rbx
	addq $16, %rbx			
	addq %rbx, %rax			# %rax recebe novo endereço
	jmp verificaFim			
    # fim loop do while


    semBlocos:
	movq $0, %rax
	jmp retFirstFit

    verificaSplit:
	cmpq %rdi, 8(%rax)		# verifica se o tamanho é exatamente igual
	je retFirstFit
	movq %rdi, %rbx
	addq $16, %rbx
	cmpq %rbx, 8(%rax)
	jle retFirstFit			# se o bloco livre for maior que o novo bloco + 16, split

    # split
	movq %rax, %rcx			# novo ponteiro em %rcx
	addq %rbx, %rcx			# %rcx aponta para o bloco sendo criado na divisão
	movq $0, (%rcx)			# declara novo bloco como livre
	movq 8(%rax), %r8		# carrega o tamanho do bloco antigo em %r8
	subq %rbx, %r8			# calcula tamanho do novo bloco
	movq %r8, 8(%rcx)		# salva o tamanho na parte gerencial

    retFirstFit:
	addq $8, %rsp			# desaloca variavel que aponta para o bloco sendo analisado
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


	# verifica se o bloco passado está alocado na heap
	cmpq %rdi, topoInicialHeap
	jge fimLiberaMem
	cmpq %rdi, topoFinalHeap
	jl fimLiberaMem

	subq $16, %rdi		# volta o ponteiro para a parte gerencial
	movq $0, (%rdi)		# indica que o bloco está livre

    # verifica bloco posterior
	movq 8(%rdi), %rcx	# carrega tamanho do bloco a ser liberado em %rcx
	addq $16, %rcx
	movq %rcx, %rbx
	addq %rdi, %rbx		# %rbx recebe endereço do bloco posterior
	cmpq topoFinalHeap, %rbx	# verifica se o bloco a ser desalocado é o último 
	je verificaPrimeiroBloco
	cmpq $0, (%rbx)		# verifica se o bloco posterior está livre
	jne verificaPrimeiroBloco
	addq 8(%rbx), %rcx 	# rcx recebe o tamanho do bloco fusionado
	movq %rcx, 8(%rdi) 	# atualiza tamanho do bloco na heap

    verificaPrimeiroBloco:
	movq topoInicialHeap, %rax
	cmpq %rdi, %rax
	je fimLiberaMem		# se o que deseja desalocar é o primeiro, não existe bloco anterior
    encontraBlocoAnterior:
	movq %rax, %rbx		# guarda endereço atual em %rbx
	movq 8(%rax), %rax	# carrega tamanho do bloco sendo analisado em  %rax
	addq $16, %rax
	addq %rbx, %rax
	cmpq %rdi, %rax		# verifica se o próximo bloco é o bloco a ser liberado
	je blocoAnteriorEncontrado
	jmp encontraBlocoAnterior

    blocoAnteriorEncontrado:
	movq (%rbx), %rcx	# carrega informação gerencial do bloco anterior em %rcx
	cmpq $0, %rcx		# verifica se o bloco anterior está livre
	jne fimLiberaMem	# se não estiver livre, não há fusão de nodos
	movq 8(%rbx), %rcx	# carrega tamanho do bloco anterior em %rcx
	addq $16, %rcx
	addq 8(%rdi), %rcx	# soma tamanho do bloco a ser liberado
	movq %rcx, 8(%rbx)	# salva novo tamanho no bloco anterior

    fimLiberaMem:
	popq %rbp
	ret





.globl imprimeMapa
imprimeMapa:
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp				# aloca espaço para variável local
	movq topoInicialHeap, %rax		# carrega inicio da heap em %rax
	movq topoFinalHeap, %r13		# carrega fim da heap em %rbx
	movq %rax, -8(%rbp)			# salva o inicio da heap na variavel local

    verificaFimHeap:
	cmpq %r13, -8(%rbp)		# verifica se o ponteiro (variável local) chegou ao fim da heap
	jge fimHeap
	movq $STR_GERENCIAL, %rsi 	# início do buffer 
	movq $16, %rdx			# tam do buffer
	movq $1, %rax			# código do comando syscall write
	movq $1, %rdi			# stdout
	syscall				# syscall write

	movq -8(%rbp), %rbx		# carrega ponteiro em rbx
	movq $0, %r12			# inicializa contador de bytes impressos em r8
	movq 8(%rbx), %r14		# carrega tamanho do bloco em rcx
	movq (%rbx), %rbx		# pega o bit de ocupacao do bloco

    verificaFimBloco:
	cmpq %r14, %r12			# verifica se o contador de bytes impressos é igual ao tamanho do bloco
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
	addq $1, %r12			# atualiza contador de bytes impressos
	jmp verificaFimBloco		# volta a verififcar se ainda restam blocos para imprimir

    fimBloco:
	addq $16, %r14
	addq %r14, -8(%rbp)		# salva o novo ponteiro na variável local
	jmp verificaFimHeap		# volta a verififcar se ainda restam blocos para imprimir

    fimHeap:
    movq $1, %rdi			# argumentos para o syscall write
	movq $1, %rdx
	movq $1, %rax
	movq $NOVA_LINHA, %rsi		# fima da impressão. pula para a próxima linha
	syscall

	addq $8, %rsp
	popq %rbp
	ret
