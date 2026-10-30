/* Embedded femtoscheme adapter. The editor owns main; no SBCL or REPL process. */
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "llt/llt.h"
#include "flisp.h"
extern void interface_init(void);
extern value_t fl_file(value_t *, uint32_t);
extern value_t fl_buffer(value_t *, uint32_t);
extern value_t fl_iowrite(value_t *, uint32_t);
extern value_t fl_ioseek(value_t *, uint32_t);
extern value_t fl_read(value_t *, uint32_t);
int scheme_error = 0;
static char result[8192];

char *scheme_eval(char *expr)
{
    int compiled = symbol_value(symbol("schemer-eval-string")) != UNBOUND &&
                   symbol_value(symbol("*schemer-enabled*")) != FL_F;
    char *source = malloc(strlen(expr) * 2 + 256);
    if (!source) { scheme_error = 1; return "Out of memory"; }
    if (compiled) {
        char *quoted = malloc(strlen(expr) * 2 + 1), *q = quoted;
        if (!quoted) { free(source); scheme_error=1; return "Out of memory"; }
        for (const unsigned char *p=(const unsigned char *)expr; *p; p++) {
            if (*p=='\\' || *p=='"') { *q++='\\'; *q++=*p; }
            else if (*p=='\n') { *q++='\\'; *q++='n'; }
            else if (*p=='\r') { *q++='\\'; *q++='r'; }
            else if (*p=='\t') { *q++='\\'; *q++='t'; }
            else *q++=*p;
        }
        *q=0;
        sprintf(source, "(let ((b (open-output-string))) (write (schemer-eval-string \"%s\") b) (get-output-string b))", quoted);
        free(quoted);
    } else sprintf(source, "(let ((b (open-output-string))) (write (begin %s) b) (get-output-string b))", expr);
    scheme_error = 0;
    value_t port = FL_NIL, value = FL_NIL;
    fl_gc_handle(&port);
    fl_gc_handle(&value);
    FL_TRY_EXTERN {
        port = fl_buffer(NULL, 0);
        value_t args[2] = {port, cvalue_static_cstring(source)};
        fl_iowrite(args, 2);
        args[1] = fixnum(0);
        fl_ioseek(args, 2);
        value = fl_read(&port, 1);
        value = fl_toplevel_eval(value);
        snprintf(result, sizeof(result), "%s", (char *)cvalue_data(value));
    } FL_CATCH_EXTERN {
        scheme_error = 1;
        snprintf(result, sizeof(result), "Scheme evaluation failed");
        fl_print(ios_stderr, fl_lasterror);
        ios_putc('\n', ios_stderr);
    }
    fl_free_gc_handles(2);
    free(source);
    return result;
}

int init_scheme(int heap_k)
{
    fl_init((size_t)heap_k * 1024);
    value_t args[2];
    args[0] = FL_NIL; args[1] = FL_NIL;
    fl_gc_handle(&args[0]); fl_gc_handle(&args[1]);
    FL_TRY_EXTERN {
        value_t install = symbol_value(symbol("*install-dir*"));
        const char *directory = install == UNBOUND ? "." : cvalue_data(install);
        char path[4096];
        snprintf(path, sizeof(path), "%s/femtoscheme/femtoscheme.boot", directory);
        args[0] = cvalue_static_cstring(path);
        args[1] = symbol(":read");
        value_t file = fl_file(args, 2);
        if (fl_load_system_image(file)) exit(1);
        interface_init();
        install = symbol_value(symbol("*install-dir*"));
        directory = install == UNBOUND ? "." : cvalue_data(install);
        snprintf(path, sizeof(path), "%s/scheme/init.scm", directory);
        args[0] = cvalue_static_cstring(path);
        (void)fl_applyn(1, symbol_value(symbol("load")), args[0]);
    } FL_CATCH_EXTERN {
        ios_puts("femtoscheme initialization failed:\n", ios_stderr);
        fl_print(ios_stderr, fl_lasterror);
        exit(1);
    }
    fl_free_gc_handles(2);
    return 0;
}
