#pragma author WerWolv
#pragma description BSON (Binary JSON)

#pragma MIME application/bson

import std.array;
import std.mem;
import type.time;
import type.magic;

enum Type : u8 {
    Double              = 0x01,
    String              = 0x02,
    EmbeddedDocument    = 0x03,
    Array               = 0x04,
    Binary              = 0x05,
    Undefined           = 0x06,
    ObjectId            = 0x07,
    Boolean             = 0x08,
    UTCDatetime         = 0x09,
    Null                = 0x0A,
    Regex               = 0x0B,
    DBPointer           = 0x0C,
    JavaScript          = 0x0D,
    Symbol              = 0x0E,
    JavaScriptWithScope = 0x0F,
    Int32               = 0x10,
    Timestamp           = 0x11,
    Int64               = 0x12,
    Decimal128          = 0x13,

    MinKey              = 0xFF,
    MaxKey              = 0x7F
};

enum Subtype : u8 {
    GenericBinarySubtype   = 0x00,
    Function               = 0x01,
    BinaryOld              = 0x02,
    UUIDOld                = 0x03,
    UUID                   = 0x04,
    MD5                    = 0x05,
    EncryptedBSONValue     = 0x06,
    CompressedBSONColumn   = 0x07,
    UserDefined            = 0x80
};

struct Binary {
    s32 length;
    Subtype subtype;
    u8 data[length];
};

struct String {
    u32 length [[hidden]];
    char value[length];
} [[sealed, format("format_string")]];

struct CString {
    char value[];
} [[sealed, format("format_string")]];

fn format_string(auto string) {
    return string.value;
};

struct ObjectId {
    type::time32_t timestamp;
    u8 randomValue[5];
    u24 counter;
};

struct DBPointer {
    String name;
    ObjectId value;
};


using Document;

struct Element {
    Type type;

    CString name;

    match (type) {
        (Type::Double): double value;
        (Type::String): String value;
        (Type::EmbeddedDocument): Document value;
        (Type::Array): Document value;
        (Type::Binary): Binary value;
        (Type::Undefined): { /* undefined */ }
        (Type::ObjectId): ObjectId value;
        (Type::Boolean): bool value;
        (Type::UTCDatetime): type::time64_t value;
        (Type::Null): { /* null */ }
        (Type::Regex): {
            CString regexPattern;
            CString regexOptions;
        }
        (Type::DBPointer): DBPointer value;
        (Type::JavaScript): String value;
        (Type::Symbol): String value;
        (Type::JavaScriptWithScope): String value;
        (Type::Int32): s32 value;
        (Type::Timestamp): u64 value;
        (Type::Int64): s64 value;
        (Type::Decimal128): u128 value;
    }
};

struct Document {
    s32 listLength;
    std::ByteSizedArray<Element, listLength - 5> elements;
    type::Magic<"\0"> endOfDocument;
};

Document documents[while(!std::mem::eof())] @ 0x00 [[inline]];
