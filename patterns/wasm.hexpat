#pragma author Mrmaxmeier
#pragma description WebAssembly 1.0 Module Format
#pragma magic [ 00 61 73 6D 01 00 00 00 ]
#pragma MIME application/wasm
#pragma endian little

// Reference: https://webassembly.github.io/spec/core/binary/index.html
// Note: This implements the bare-minimum to fully decode a WebAssembly 1.0 module.
// We should add names to each instruction and to the other non-descriptive matches.

import std.mem;
import type.magic;
import type.leb128;

// Note: We're not enforcing type limits here.
using U32 = type::uLEB128;

struct Vec<T> {
  U32 count;
  T elems[count];
};

// Indices
using TypeIdx = U32;
using FuncIdx = U32;
using TableIdx = U32;
using MemIdx = U32;
using GlobalIdx = U32;
using ElemIdx = U32;
using DataIdx = U32;
using LocalIdx = U32;
using LabelIdx = U32;

// Types
enum NumType : u8 {
  I32 = 0x7f,
  I64 = 0x7e,
  F32 = 0x7d,
  F64 = 0x7c,
};

enum VecType : u8 {
  V128 = 0x7b,
};

enum RefType : u8 {
  FuncRef = 0x70,
  ExternRef = 0x6f,
};

enum ValType : u8 {
  I32 = 0x7f,
  I64 = 0x7e,
  F32 = 0x7d,
  F64 = 0x7c,
  V128 = 0x7b,
  FuncRef = 0x70,
  ExternRef = 0x6f,
};

using ResultType = Vec<ValType>;

struct FuncType {
  type::Magic<"\x60"> start;
  ResultType parameters;
  ResultType results;
};

struct Limits {
  u8 kind;
  U32 n;
  if (kind == 1) {
    U32 m;
  }
};
using MemType = Limits;

struct TableType {
  RefType et;
  Limits lim;
};

enum Mut : u8 {
  Const = 0,
  Mut = 1,
};

struct GlobalType {
  ValType t;
  Mut m;
};

struct Name {
  U32 len;
  char name[len];
};


// Sections
enum SectionId : u8 {
  Custom = 0,
  Type = 1,
  Import = 2,
  Function = 3,
  Table = 4,
  Memory = 5,
  Global = 6,
  Export = 7,
  Start = 8,
  Element = 9,
  Code = 10,
  Data = 11,
  DataCount = 12,
};

struct Custom<auto size> {
    Name name;
    std::mem::Bytes<(size-sizeof(name))> data;
};

struct Import {
  Name mod;
  Name nm;
  u8 kind;
  match (kind) {
    (0): TypeIdx x;
    (1): TableType tt;
    (2): MemType mt;
    (3): GlobalType gt;
  }
};

using Table = TableType;
using Mem = MemType;

struct BlockType {
  u8 kind;
  // FIXME: also allow s33 encoding
};

struct memarg {
  U32 align;
  U32 offset;
};

// Note: We're not constructing an instruction tree here, just linear instructions
// Should this be how we handle instructions?
struct Instruction {
  u8 opcode;
  // TODO: set name for all opcodes?
  // Note: we only handle ones with extra data currently
  match (opcode) {
    // Control Instructions
    (0x02 | 0x03 | 0x04): BlockType bt;
    (0x0c | 0x0d): LabelIdx l;
    (0x0e): {
      Vec<LabelIdx> labels;
      LabelIdx default;
    }
    (0x10): FuncIdx x;
    (0x11): {
      TypeIdx y;
      TableIdx x;
    }

    // Reference Instructions
    (0xd0): RefType t;
    (0xd2): FuncIdx x;

    // Parametric Instructions
    (0x1c): Vec<ValType> t;

    // Variable Instructions
    (0x20 | 0x21 | 0x22): LocalIdx x;
    (0x23 | 0x24): GlobalIdx x;

    // Table Instructions
    (0x25 | 0x26): TableIdx x;
    (0xfc): {
      U32 opcode_ext;
      match (opcode_ext) {
        (12): {
          ElemIdx y;
          TableIdx x;
        }
        (13): ElemIdx x;
        (14): {
          TableIdx x;
          TableIdx y;
        }
        (15 | 16 | 17): TableIdx x;
      }
    }

    // Memory Instructions
    (0x28 | 0x29 | 0x2a | 0x2b | 0x2c | 0x2d | 0x2e | 0x2f | 0x30 | 0x31 | 0x32 | 0x33 | 0x34 | 0x35 | 0x36 | 0x37 | 0x38 | 0x39 | 0x3a | 0x3b | 0x3c | 0x3d | 0x3e): memarg m;
    (0x3f | 0x40): type::Magic<"\x00"> memory;
    (0xfc): {
      U32 opcode_ext;
      match (opcode_ext) {
        (8): {
          DataIdx x;
          type::Magic<"\x00"> memory;
        }
        (9): DataIdx x;
        (10): type::Magic<"\x00\x00"> unk;
        (11): type::Magic<"\x00"> memory;
      }
    }

    // Numeric Instructions
    (0x41 | 0x42): type::uLEB128 n;
    (0x43): std::mem::Bytes<4> f32;
    (0x44): std::mem::Bytes<8> f64;

    // TODO: Vector Instructions
  }
};

struct Expr {
  Instruction instrs[while(std::mem::read_unsigned($, 1) != 0x0b)];
  type::Magic<"\x0b"> end;
};

struct Global {
  GlobalType gt;
  Expr e;
};

struct Export {
  Name nm;
  u8 kind;
  match (kind) {
    (0): FuncIdx x;
    (1): TableIdx x;
    (2): MemIdx x;
    (3): GlobalIdx x;
  }
};

using Start = FuncIdx;


using ElemKind = type::Magic<"\x00">;
struct Elem {
  u8 kind;
  match (kind) {
    (0): {
      Expr e;
      Vec<FuncIdx> y;
    }
    (1): {
      ElemKind et;
      Vec<FuncIdx> y;
    }
    (2): {
      TableIdx x;
      Expr e;
      ElemKind et;
      Vec<FuncIdx> y;
    }
    (3): {
      ElemKind et;
      Vec<FuncIdx> y;
    }
    (4): {
      Expr e;
      Vec<Expr> el;
    }
    (5): {
      RefType et;
      Vec<Expr> el;
    }
    (6): {
      TableIdx x;
      Expr e;
      RefType et;
      Vec<Expr> el;
    }
    (7): {
      RefType et;
      Vec<Expr> el;
    }
  }
};

struct Locals {
  U32 n;
  ValType t;
};

struct Func {
  Vec<Locals> locals;
  Expr expr;
};

struct Code {
  U32 size;
  Func func [[fixed_size(size)]];
};

struct Data {
  u8 kind;
  match (kind) {
    (0): {
      Expr e;
      Vec<char> init;
    }
    (1): Vec<char> init;
    (2): {
      MemIdx x;
      Expr e;
      Vec<char> init;
    }
  }
};

struct Section {
  SectionId id;
  U32 size;

  match (id) {
    (SectionId::Custom): Custom<size> customsec [[fixed_size(size)]];
    (SectionId::Type): Vec<FuncType> typesec [[fixed_size(size)]];
    (SectionId::Import): Vec<Import> importsec [[fixed_size(size)]];
    (SectionId::Function): Vec<TypeIdx> funcsec [[fixed_size(size)]];
    (SectionId::Table): Vec<Table> tablesec [[fixed_size(size)]];
    (SectionId::Memory): Vec<Mem> memsec [[fixed_size(size)]];
    (SectionId::Global): Vec<Global> globalsec [[fixed_size(size)]];
    (SectionId::Export): Vec<Export> exportsec [[fixed_size(size)]];
    (SectionId::Start): Start start [[fixed_size(size)]];
    (SectionId::Element): Vec<Elem> elemsec [[fixed_size(size)]];
    (SectionId::Code): Vec<Code> codesec [[fixed_size(size)]];
    (SectionId::Data): Vec<Data> datasec [[fixed_size(size)]];
    (SectionId::DataCount): U32 datacountsec [[fixed_size(size)]];
    (_): std::mem::Bytes<size> unknown;
  }
};

struct Module {
  type::Magic<"\0asm"> magic;
  type::Magic<"\x01\x00\x00\x00"> version;
  Section sections[while(!std::mem::eof())];
};

Module module @ 0x00;
