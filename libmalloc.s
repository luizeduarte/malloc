#ifndef MALLOC_H_
#define MALLOC_H_

extern long int iniciaAlocador();
extern void *alocaMem(long int num_bytes);
extern long int finalizaAlocador();
extern void liberaMem(void *bloco);

extern long int TopoInicialHeap;
extern long int TopoFinalHeap;

#endif