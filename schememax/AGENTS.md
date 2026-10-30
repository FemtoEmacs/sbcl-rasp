# Native compiled Scheme integration

Read README.md and schemer/README.md. The user authorized the Schemer/Wasmtime
migration, retaining legacy handlers temporarily and requiring no Node.js.

- The C editor stays native. Schemer compiles compatible code to WasmGC;
  Wasmtime is embedded through its C API. Never introduce a JavaScript engine
  or a Node dependency, including in the permanent tests or build scripts.
- Keep the compiler isolated from editor macros. schemer-compile runs the
  self-hosted schemer/compiler.wasm through Wasmtime, with direct process arguments.
  Never interpolate source or paths into shell commands.
- Use finalized exception handling for Wasmtime. Browsers accepting legacy
  `try`/`catch` does not prove a module will validate in the native runtime.
- Native editor offsets and legacy LENGTH on strings count UTF-8 bytes.
  Preserve that adaptation for compiled command bodies; ordinary user code
  keeps R7RS semantics. Do not pass opaque native objects or procedures over
  the text callback protocol; select compatibility before execution.
- Never retry a failed compiled editing operation in the interpreter: it may
  already have changed a buffer, saved a file or run a process.
- Wasmtime GC values retained in C must be rooted and explicitly unrooted.
  Free retained modules and cache buffers on shutdown.
- Back up changed existing files in a sibling bkp/ folder. The complete
  pre-migration editor backup is under the repository's bkp/ folder.
- Run make, make check, make check-ui, and make check-selfhost. make check includes ten compiler
  fixtures and native integration checks; all use C, Scheme and shell.
- Test editor keyboard, prompt and file-save behavior with disposable files.
  Do not use real user documents or contact live assistant providers.
- Wasmtime supports Linux/macOS/Windows, but do not describe the existing
  terminal/GUI C code as ported to an OS until it has been built and tested.

Help-menu wrappers menu-chatgpt/menu-claude pass native procedures to
call-in-window-of. Keep this higher-order operation on the compatibility
path in command compilation and expression evaluation; a procedure is not
readable data for the text RPC bridge. Native assistant entry points remain
compatible too. tests/compiled.scm exercises both real wrapper definitions
with mocked window and provider functions, plus direct callback evaluation.

Save As uses getfilename_default for editable current filenames and real
filename completion; never route it back through generic getinput. Browsered
must wrap getfilename_default as well as getfilename so unnamed buffers use
the remembered browser folder. Test existing and unnamed buffers, directory
and filename TAB completion, Unicode and cancellation without disk writes.
