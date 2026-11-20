/*
Copyright (c) 2026 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Emilio J. Gallego Arias
*/

#include "interpreter_bridge.h"

#include "package/decl_provider.h"

#include <stddef.h>
#include <stdint.h>

#include "library/ir_interpreter.h"
#include "runtime/object.h"

extern "C" {
extern lean_object * l_ByteArray_empty;
}

namespace lean {
namespace {

object * mk_some_borrowed(object * value) {
    object * obj = lean_alloc_ctor(1, 1, 0);
    lean_inc(value);
    lean_ctor_set(obj, 0, value);
    return obj;
}

} // namespace

namespace vir {

void ensure_runtime_initialized() {
    static bool initialized = false;
    if (!initialized) {
        initialize_object();
        initialized = true;
    }
}

void ensure_ir_interpreter_initialized() {
    static bool initialized = false;
    if (!initialized) {
        ensure_runtime_initialized();
        initialize_ir_interpreter();
        l_ByteArray_empty = lean_mk_empty_byte_array(lean_box(0));
        lean_mark_persistent(l_ByteArray_empty);
        initialized = true;
    }
}

object * run_interpreter_function(object * fn_obj, size_t argc, object ** args) {
    ensure_ir_interpreter_initialized();
    return run_package_interpreter_function(fn_obj, argc, args);
}

} // namespace vir

namespace {

// Run Lean's object runtime initialization from the reactor's `_initialize`
// (and WASI command `_start`) so external classes, `g_array_empty`, and
// `g_saved_stderr` are initialized before any export executes.
struct runtime_initializer {
    runtime_initializer() {
        vir::ensure_runtime_initialized();
    }
};

static runtime_initializer g_runtime_initializer;

} // namespace
} // namespace lean

extern "C" lean::object * lean_ir_find_env_decl(lean::object * env, lean::object * n) {
    lean::object * result = lean_box(0);
    if (lean::object * decl = lean::vir::find_package_decl(n)) {
        result = lean::mk_some_borrowed(decl);
    }
    lean_dec(env);
    lean_dec(n);
    return result;
}

extern "C" lean::object * lean_ir_find_env_decl_boxed(lean::object * env, lean::object * n) {
    lean::object * result = lean_box(0);
    if (lean::object * decl = lean::vir::find_package_boxed_decl(n)) {
        result = lean::mk_some_borrowed(decl);
    }
    lean_dec(env);
    lean_dec(n);
    return result;
}

extern "C" uint32_t vir_upstream_target_pointer_bytes(void) {
    return sizeof(void *);
}
