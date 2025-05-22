#pragma author WerWolv
#pragma description Minecraft NBT

import std.sys;

#pragma endian big

enum Tag : u8 {
    End = 0,
    Byte = 1,
    Short = 2,
    Int = 3,
    Long = 4,
    Float = 5,
    Double = 6,
    ByteArray = 7,
    String = 8,
    List = 9,
    Compound = 10,
    IntArray = 11,
    LongArray = 12
};

using Element;

struct Value {
    match (parent.tag) {
        (Tag::Byte): s8 value;
        (Tag::Short): s16 value;
        (Tag::Int): s32 value;
        (Tag::Long): s64 value;
        (Tag::Float): float value;
        (Tag::Double): double value;
        (Tag::ByteArray): {
            s32 arrayLength;
            s8 value[arrayLength] [[sealed]];
        }
        (Tag::String): {
            u16 stringLength;
            char value[stringLength];
        }
        (Tag::List): {
            Tag tag;
            s32 listLength;
            Value values[listLength] [[static]];
        }
        (Tag::Compound): Element values[while(true)];
        (Tag::IntArray): {
            s32 arrayLength;
            s32 value[arrayLength] [[sealed]];
        }
        (Tag::LongArray): {
            s32 arrayLength;
            s64 value[arrayLength] [[sealed]];
        }
        (_): std::error(std::format("Invalid tag {:02X}", TypeTag));
    }
} [[inline]];

struct Element {
    Tag tag;
    if (tag == Tag::End)
        break;
    else {

        u16 nameLength;
        char name[nameLength];

        Value value;
    }
};

struct NBT {
    Element element[while(true)] [[inline]];
};

NBT nbt @ 0x00;
