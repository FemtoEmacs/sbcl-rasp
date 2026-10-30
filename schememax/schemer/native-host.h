#ifndef SCHEMER_NATIVE_HOST_H
#define SCHEMER_NATIVE_HOST_H
#include <stddef.h>
typedef struct sc_module sc_module;
typedef char *(*sc_editor_fn)(const char *, void *);
sc_module *sc_module_open(const unsigned char *, size_t, sc_editor_fn, void *, char **);
void sc_module_set_input(sc_module *, const char *);
int sc_module_run(sc_module *, int, char **, char **, char **);
void sc_module_close(sc_module *);
#endif
