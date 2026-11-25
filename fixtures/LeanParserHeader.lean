/-
Copyright (c) 2026 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Emilio J. Gallego Arias
-/

module

public import Lean.Parser.Module
public import Lean.ConstMap

public section

namespace Vir.Fixtures.LeanParserHeader

open Lean Parser

unsafe def parseHeaderScore (input : String) : Nat :=
  match unsafeIO (parseHeader (mkInputContext input "<input>")) with
  | .error _ => 1
  | .ok (_, st, messages) =>
      st.pos.byteIdx + messages.toList.length

unsafe def upstreamParseHeaderScore : Nat :=
  parseHeaderScore "import Init\npublic import Lean.Parser\n\nnamespace Demo\n"

@[noinline] private def cachedAxiomModule (table : @& ImportedConsts ConstantInfo)
    (key : @& Name) : Option Nat :=
  match table.findConstEntryCached? key with
  | some (.axiomInfo axiomInfo, index) =>
    if axiomInfo.name == key then some index else none
  | _ => none

@[noinline] private def importedLookupScore (key : Name) : Nat :=
  let value : ConstantInfo := .axiomInfo {
    name := key, levelParams := [], type := mkConst `Nat, isUnsafe := false
  }
  let table : ImportedConsts ConstantInfo := {
    tree := .merged .anonymous none #[.merged key (some (value, 7)) #[]]
  }
  let first := cachedAxiomModule table key
  let second := cachedAxiomModule table key
  (if first == some 7 then 1 else 0) + (if second == some 7 then 2 else 0) +
    (if (table.findConstEntryCached? `missing).isNone then 4 else 0)

/-- Check a populated global lookup cache on a cold lookup, a hit, and a miss. -/
def importedConstCacheScore : Nat :=
  importedLookupScore `cachedAxiom

end Vir.Fixtures.LeanParserHeader
