/-
Copyright (c) 2026 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Emilio J. Gallego Arias
-/

import Lean

open Lean Lean.IR

unsafe def main : IO Unit := do
  enableInitializersExecution
  initSearchPath (← findSysroot)
  let moduleName := `Lean.Expr
  let env ← importModules (loadExts := true) #[{ module := moduleName, importAll := true }] {}
  let some moduleIdx := env.header.moduleNames.findIdx? (· == moduleName)
    | throw (IO.userError s!"missing module {moduleName}")
  for decl in declMapExt.getModuleIREntries env moduleIdx do
    if let .fdecl .. := decl then
      if env.getModuleIdxFor? decl.name == some moduleIdx then
        IO.println decl.name
