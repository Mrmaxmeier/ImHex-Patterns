#pragma description Raw LLVM InstrProf Profile Data
#pragma endian little

import std.array;
import std.mem;
import type.magic;
import type.base;
import type.leb128;


/* Explainer: https://leodido.dev/demystifying-profraw/

$ for v in (seq 10 21); echo LLVM $v :; curl --silent https://raw.githubusercontent.com/llvm/llvm-project/refs/heads/release/$v.x/llvm/include/llvm/ProfileData/InstrProfData.inc | grep "INSTR_PROF_RAW_VERSION "; end
Version 7: LLVM 13
Version 8: LLVM 14-17
Version 9: LLVM 18
Version 10: LLVM 19+

Header layouts:
 7 - https://github.com/llvm/llvm-project/blob/release/13.x/llvm/include/llvm/ProfileData/InstrProfData.inc#L123-L142
 8 - https://github.com/llvm/llvm-project/blob/release/17.x/llvm/include/llvm/ProfileData/InstrProfData.inc#L121-L143
 9 - https://github.com/llvm/llvm-project/blob/release/18.x/llvm/include/llvm/ProfileData/InstrProfData.inc#L124-L150
10 - https://github.com/llvm/llvm-project/blob/release/19.x/llvm/include/llvm/ProfileData/InstrProfData.inc#L145-L173

Profile reading is implemented in InstrProfReader.cpp
template <class IntPtrT>
Error RawInstrProfReader<IntPtrT>::readHeader(
    const RawInstrProf::Header &Header) {
*/


// How many padding bytes for 8-byte aligned area?
fn getNumPaddingBytes(u64 size) {
    return 7 & (8 - size % 8);
};

struct Header {
    type::Magic<"\x81rforpl\xff"> Magic;
    u64 Version;
    std::assert(Version <= 10, "unexpected version or feature flags");
    u64 BinaryIdsSize;
    u64 NumData;
    u64 PaddingBytesBeforeCounters;
    u64 NumCounters;
    u64 PaddingBytesAfterCounters;
    if (Version >= 9) {
        u64 NumBitmapBytes;
        u64 PaddingBytesAfterBitmapBytes;
    }
    u64 NamesSize;
    s64 CountersDelta;
    if (Version >= 9) {
      s64 BitmapDelta;
    }
    s64 NamesDelta;
    if (Version >= 10) {
        u64 NumVTables;
        u64 VNamesSize;
    }
    u64 ValueKindLast;
    std::assert(ValueKindLast == 1, "unexpected ValueKindLast, failed to decode header?");
};

struct Data<auto Version> {
    type::Hex<u64> NameRef;
    type::Hex<u64> FuncHash;
    s64 CounterPtr;
    if (Version >= 9) {
        s64 BitmapPtr;
    }
    s64 FunctionPointer;
    u64 Values;
    u32 NumCounters;
    u16 NumValueSites[2];
    if (Version >= 9) {
        u32 NumBitmapBytes;
    }
};

struct Names {
    type::uLEB128 UncomressedSize;
    type::uLEB128 CompressedSize;
    std::mem::Bytes<CompressedSize> Data;
};

// RawInstrProfReader<IntPtrT>::readHeader
struct ProfRaw {
    Header header;
    u64 PaddingBytesAfterNames = getNumPaddingBytes(header.NamesSize);

    // Xref readBinaryIdsInternal
    std::mem::Bytes<header.BinaryIdsSize> BinaryIds;

    Data<header.Version> Datas[header.NumData];

    padding[header.PaddingBytesBeforeCounters];
    u64 CountersSectionSize = header.NumCounters * 8;
    u64 Counters[header.NumCounters];
    padding[header.PaddingBytesAfterCounters];
    if (header.Version >= 9) {
        std::mem::Bytes<header.NumBitmapBytes> Bitmap;
        padding[header.PaddingBytesAfterBitmapBytes];
    }
    std::ByteSizedArray<Names, header.NamesSize> Names;
    padding[PaddingBytesAfterNames];
    if (header.Version >= 10) {
        padding[header.PaddingBytesAfterVTable];
        padding[getNumPaddingBytes(header.VNamesSize)];
    }
};

ProfRaw profile @ 0x00;
