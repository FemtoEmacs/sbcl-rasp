/* Standalone compiled Schemer driver. Links Wasmtime, never FemtoScheme. */
#include "native-host.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *read_all(const char *path, size_t *size)
{
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    char *s = NULL, block[8192];
    size_t capacity = 0, n = 0, count;
    while ((count = fread(block, 1, sizeof block, f))) {
        if (n + count + 1 > capacity) {
            capacity = (n + count + 1) * 2;
            char *next = realloc(s, capacity);
            if (!next) { free(s); fclose(f); return NULL; }
            s = next;
        }
        memcpy(s + n, block, count);
        n += count;
    }
    int bad = ferror(f);
    fclose(f);
    if (bad) { free(s); return NULL; }
    if (!s) s = malloc(1);
    if (!s) return NULL;
    s[n] = 0;
    if (size) *size = n;
    return s;
}

/* Quote source as data for compiler-main.scm, never as an expression to run. */
static char *source_request(const char *s, size_t n, int strict)
{
    char *request = malloc(n * 4 + 96);
    if (!request) return NULL;
    char *p = request;
    *p++ = '(';
    *p++ = '"';
    for (size_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char)s[i];
        if (c == '"' || c == '\\') { *p++ = '\\'; *p++ = (char)c; }
        else if (c == '\n') { *p++ = '\\'; *p++ = 'n'; }
        else if (c == '\r') { *p++ = '\\'; *p++ = 'r'; }
        else if (c == '\t') { *p++ = '\\'; *p++ = 't'; }
        else if (!c) { free(request); return NULL; }
        else *p++ = (char)c;
    }
    strcpy(p, strict ? "\" () () #f #f)" : "\" () () #f #t)");
    return request;
}

static int nibble(char c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    return -1;
}

int main(int argc, char **argv)
{
    int source = 0, strict = 0, i = 1;
    for (; i < argc && argv[i][0] == '-'; i++) {
        if (!strcmp(argv[i], "--source")) source = 1;
        else if (!strcmp(argv[i], "--strict")) strict = 1;
        else { fprintf(stderr, "Unknown compiler option\n"); return 2; }
    }
    if (argc - i != 3) {
        fprintf(stderr, "Usage: schemer-compile [--source] [--strict] INPUT OUTPUT INSTALL-DIRECTORY\n");
        return 2;
    }
    const char *input = argv[i], *output_path = argv[i + 1], *root = argv[i + 2];
    char module_path[4096];
    if (snprintf(module_path, sizeof module_path, "%s/schemer/compiler.wasm", root)
            >= (int)sizeof module_path) return 2;
    size_t size = 0, n = 0;
    char *bytes = read_all(module_path, &size), *text = read_all(input, &n);
    if (!bytes || !text) {
        fprintf(stderr, "Cannot read compiler module or input\n");
        free(bytes); free(text); return 1;
    }
    char *request = source ? source_request(text, n, strict) : text;
    if (source) free(text);
    if (!request) { free(bytes); return 1; }
    char *error = NULL, *value = NULL, *output = NULL;
    sc_module *module = sc_module_open((unsigned char *)bytes, size, NULL, NULL, &error);
    free(bytes);
    int ok = module != NULL;
    if (ok) {
        sc_module_set_input(module, request);
        ok = sc_module_run(module, 0, &value, &output, &error);
    }
    free(request);
    if (!ok) {
        fprintf(stderr, "%s%s%s\n", output ? output : "", output && *output ? "\n" : "",
                error ? error : "Compiled compiler failed");
        goto done;
    }
    n = strlen(output);
    if (n < 16 || (n & 1) || strncmp(output, "0061736d", 8)) {
        fprintf(stderr, "Compiler did not return a WebAssembly module\n");
        ok = 0; goto done;
    }
    unsigned char *wasm = malloc(n / 2);
    if (!wasm) { ok = 0; goto done; }
    for (size_t k = 0; k < n; k += 2) {
        int hi = nibble(output[k]), lo = nibble(output[k + 1]);
        if (hi < 0 || lo < 0) {
            free(wasm); ok = 0;
            fprintf(stderr, "Invalid compiler output\n"); goto done;
        }
        wasm[k / 2] = (unsigned char)(hi * 16 + lo);
    }
    /* Compilation errors leave an existing destination untouched. */
    FILE *f = fopen(output_path, "wb");
    ok = f != NULL;
    if (f) {
        ok = fwrite(wasm, 1, n / 2, f) == n / 2;
        if (fclose(f)) ok = 0;
    }
    free(wasm);
    if (!ok) fprintf(stderr, "Cannot write compiler output\n");
done:
    sc_module_close(module);
    free(error); free(value); free(output);
    return ok ? 0 : 1;
}
