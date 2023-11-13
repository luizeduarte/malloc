#ifndef MALLOC_H_
#define MALLOC_H_

long int iniciaAlocador();
void *alocaMem(long int num_bytes);
long int finalizaAlocador();
void liberaMem(void *bloco);
void imprimeMapa();

extern long int TopoInicialHeap;
extern long int TopoFinalHeap;

#endif