#pragma description ASN.1 Binary Encoding (X.690 BER/CER/DER)

// Reference: https://en.wikipedia.org/wiki/X.690#BER_encoding

//  We don't handle indefinite length encodings here and this pattern
// definition is quite barebones. It doesn't decode any of the primitive
// types, only the ASN.1 object tree structure.

// Notably, structures like X.509 certificates or OCSP responses can't be fully
// parsed with this since we can't parse through encapsulated objects:
// https://stackoverflow.com/questions/15299201/asn-1-octet-strings

import std.string;
import std.mem;
import std.array;

enum TagClass : u8 {
    UNIVERSAL          = 0x00,
    APPLICATION        = 0x01,
    CONTEXT_SPECIFIC   = 0x02,
    PRIVATE            = 0x03,
};

enum PC : u8 {
    PRIMITIVE          = 0x00,
    CONSTRUCTED        = 0x01,
};

// Note that this doesn't include the long form primitive tags.
enum TagType : u8 {
    END_OF_CONTENT     = 0x00,

    BOOLEAN            = 0x01,
    INTEGER            = 0x02,
    BIT_STRING         = 0x03,
    OCTET_STRING       = 0x04,
    NULL               = 0x05,
    OBJECT_IDENTIFIER  = 0x06,
    OBJECT_DESCRIPTOR  = 0x07,
    EXTERNAL           = 0x08,
    REAL               = 0x09,
    ENUMERATED         = 0x0A,
    EMBEDDED_PDV       = 0x0B,
    UTF8_STRING        = 0x0C,
    RELATIVE_OID       = 0x0D,
    TIME               = 0x0E,
    RESERVED           = 0x0F,
    SEQUENCE           = 0x10,
    SET                = 0x11,
    NUMERIC_STRING     = 0x12,
    PRINTABLE_STRING   = 0x13,
    T61_STRING         = 0x14,
    VIDEOTEX_STRING    = 0x15,
    IA5_STRING         = 0x16,
    UTC_TIME           = 0x17,
    GENERALIZED_TIME   = 0x18,
    GRAPHIC_STRING     = 0x19,
    VISIBLE_STRING     = 0x1A,
    GENERAL_STRING     = 0x1B,
    UNIVERSAL_STRING   = 0x1C,
    BMP_STRING         = 0x1E,

    LONG_FORM          = 0x1F,
};

bitfield Type {
    TagType type : 5;
    PC pc : 1;
    TagClass class : 2;
};

struct Length {
    u8 first_byte;
    if (first_byte >= 0x80) {
        u8 length_bytes[first_byte & 0x7F];
    }
} [[sealed, format("decode_length"), transform("decode_length")]];

fn decode_length(ref Length obj) {
    if (obj.first_byte < 0x80)
        return obj.first_byte;
    else {
        u8 num_bytes = obj.first_byte & 0x7F;
        u32 length = 0;
        for (u8 i = 0, i < num_bytes, i += 1) {
            length = (length << 8) | obj.length_bytes[i];
        }
        return length;
    }
};

struct LongFormTag {
    // The top bit in each long form octet indicates that another octet follows.
    u8 first_byte;
    u8 tag_bytes[std::mem::read_unsigned($-1, 1) >= 0x80];
} [[sealed, format("decode_long_form_tag"), transform("decode_long_form_tag")]];

fn decode_long_form_tag(ref LongFormTag obj) {
    u64 tag = obj.first_byte & 0x7f;
    for (u8 i = 0, i < sizeof(obj.tag_bytes), i += 1) {
        tag = (tag << 8) | obj.tag_bytes[i] & 0x7f;
    }
    return tag;
};

// We split this into a separate type to avoid known buggy behavior with recursion and templates.
// I'd be nice to be able to just use ByteSizedArray below instead of this.
using ASN1Value;
struct ASN1Seq<auto length> {
    std::ByteSizedArray<ASN1Value, length> values;
} [[inline]];

struct ASN1Value {
    Type type;
    if (type.type == TagType::LONG_FORM) {
        LongFormTag long_form_tag;
    }
    Length length;
    match (type.pc) {
        (PC::PRIMITIVE): { std::mem::Bytes<length> value; }
        (PC::CONSTRUCTED): { ASN1Seq<length> values; }
    }
};


ASN1Value value @ 0x00;
