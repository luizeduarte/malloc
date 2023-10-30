#include <stdio.h>
struct bloco{
	int tamanho;
	int livre;
};


int alocaMem(int novoTamanho){
	//ponteiro para o primeiro bloco da lista
	struct bloco *inicio = topoInicialHeap;


	while (inicio->tamanho<novoTamanho && inicio->livre==0 && inicio<topoFinalHeap){
		inicio += inicio->tamanho;
	}

	if (inicio.tamanho == novoTamanho && inicio->livre == 1){
		inicio->livre = 0;
		inicio->tamanho = novoTamanho;
		return inicio;
	} else if (inicio.tamanho > novoTamanho && inicio->livre == 1){
		//divide o bloco 
		inicio->livre = 0;
		inicio->tamanho = novoTamanho;
		(inicio+novoTamanho)->livre = 1;
		(inicio+novoTamanho)->tamanho = inicio->tamanho - novoTamanho;
		return inicio;
	} else if (inicio > topoFinalHeap){
		//aloca mais memoria		
	}
}
