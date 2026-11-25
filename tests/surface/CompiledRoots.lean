/-
Copyright (c) 2026 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Emilio J. Gallego Arias
-/

import Lean

open Lean Lean.IR

unsafe def main (args : List String) : IO Unit := do
  let [moduleArg] := args
    | throw (IO.userError "usage: CompiledRoots MODULE")
  enableInitializersExecution
  initSearchPath (← findSysroot)
  let moduleName := moduleArg.toName
  let env ← importModules (loadExts := true) #[{ module := moduleName, importAll := true }] {}
  let some moduleIdx := env.header.moduleNames.findIdx? (· == moduleName)
    | throw (IO.userError s!"missing module {moduleName}")
  let data := env.header.moduleData[moduleIdx]!
  let headerNames := data.constNames ++ data.extraConstNames
  let mut roots := #[]
  let mut omitted := 0
  for decl in declMapExt.getModuleIREntries env moduleIdx do
    if let .fdecl .. := decl then
      if env.getModuleIdxFor? decl.name == some moduleIdx then
        roots := roots.push decl.name.toString
        if !headerNames.contains decl.name then
          omitted := omitted + 1
  IO.println <| Json.compress <| Json.mkObj [("roots", toJson roots), ("omitted", toJson omitted)]
