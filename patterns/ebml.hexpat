#pragma author flo
#pragma description Extensible Binary Meta Language (incl. mkv and webm)
#pragma magic [1A 45 DF A3] @ 0x00
#pragma mime video/x-matroska
#pragma mime audio/x-matroska
#pragma mime video/webm
#pragma mime audio/webm

#pragma endian big

/*
EBML is a binary file format composed of identical blocks (ID, data_size, data).
 - ID - indicates the meaning of the data.  These are akin to field names.
 - data_size - indicates the number of bytes in the data field
 - data - byte array with the length being data_size
ID and data_size are encoded unsigned integers, allowing for small numbers to
take up fewer bytes of data.  Technically IDs are not defined this way and the
encoded values are used in the specifications rather than their actual numerical
equivalent.

The only way to interpret the data is to know the meaning of the IDs.  This script
has many of the EBML and Mastroska IDs, but not all of them.  Any unknown IDs will
be treated as byte arrays.

References:
    EBML - https://matroska-org.github.io/libebml/specs.html
    MKV - https://www.matroska.org/index.html
    010Editor Binary Template by `scigrapher`
*/


import std.array;
import std.mem;
import type.magic;

struct EBMLNumber {
    u8 x = std::mem::read_unsigned($, 1);
    if (x & 0x80 == 0x80) {
        u8 value[1];
    } else if (x & 0xc0 == 0x40) {
        u8 value[2];
    } else if (x & 0xe0 == 0x20) {
        u8 value[3];
    } else if (x & 0xf0 == 0x10) {
        u8 value[4];
    } else if (x & 0xf8 == 0x08) {
        u8 value[5];
    } else if (x & 0xfc == 0x04) {
        u8 value[6];
    } else if (x & 0xfe == 0x02) {
        u8 value[7];
    } else if (x & 0xff == 0x01) {
        u8 value[8];
    } else {
        u8 value[9];
    }
} [[sealed, format("ebml_number_value"), transform("ebml_number_value")]];

fn ebml_number_value(ref EBMLNumber number) {
    u8 first_byte_mask = 0xff >> sizeof(number.value);
    u64 result = number.value[0] & first_byte_mask;
    for (u8 i = 1, i < sizeof(number.value), i = i + 1) {
        result = (result << 8) | number.value[i];
    }
    return result;
};

using ElementID = EBMLNumber;

struct EBMLUIntElement {
    ElementID id;
    EBMLNumber size;
    u8 data[size];
} [[sealed, format("uint_value"), transform("uint_value")]];

struct EBMLIntElement {
    EBMLNumber size;
    u8 data[size];
} [[sealed, format("int_value"), transform("int_value")]];

fn uint_value(ref EBMLUIntElement element) {
    u64 result = 0;
    for (u8 i = 0, i < element.size, i = i + 1) {
        result = result | (element.data[i] << (8 * i));
    }
    return result;
};

fn int_value(ref EBMLIntElement element) {
    // TODO: apply sign
    u64 result = 0;
    for (u8 i = 0, i < element.size, i = i + 1) {
        result = result | (element.data[i] << (8 * i));
    }
    return result;
};

struct EBMLASCIIStringElement {
    EBMLNumber size;
    char data[size];
} [[format("ascii_string_value"), transform("ascii_string_value")]];

fn ascii_string_value(ref EBMLASCIIStringElement element) { return element.data; };

struct EBMLUnicodeStringElement {
    EBMLNumber size;
    char data[size];
} [[format("unicode_string_value"), transform("unicode_string_value")]];

fn unicode_string_value(ref EBMLUnicodeStringElement element) { return element.data; };

struct EBMLFloatElement {
    EBMLNumber size;
    u8 data[size];
}; // [[sealed, format("float_value"), transform("float_value")]];

struct EBMLDateElement {
    EBMLNumber size;
    u8 data[size];
}; // [[sealed, format("date_value"), transform("date_value")]];

struct ByteElement {
    EBMLNumber size;
    std::mem::Bytes<size> data;
};

using UnknownElement = ByteElement;

using Element;
struct CompoundElement {
    EBMLNumber size;
    std::ByteSizedArray<Element, size> elements [[fixed_size(size)]];
};

struct Element {
    ElementID id;

    match (id) {
        (0xA45DFA3): CompoundElement EBML;
        (0x286): EBMLUIntElement version;
        (0x2f7): EBMLUIntElement readVersion;
        (0x2f2): EBMLUIntElement maxIDLength;
        (0x2f3): EBMLUIntElement maxSizeLength;
        (0x282): EBMLASCIIStringElement docType;
        (0x287): EBMLUIntElement docTypeVersion;
        (0x285): EBMLUIntElement docReadVersion;
        (0x6c): ByteElement void;

        // MKV segment
        (0x8538067): CompoundElement segment;
        (0x14d9b74): CompoundElement seekHead;
        (0xdbb): CompoundElement seek;
        (0x13ab): ByteElement seekID;
        (0x13ac): EBMLUIntElement seekPosition;

        // MKV info
        (0x549a966): CompoundElement info;
        (0xad7b1): EBMLUIntElement timestampScale;
        (0xd80): EBMLUnicodeStringElement muxingApp;
        (0x1741): EBMLUnicodeStringElement writingApp;
        (0x489): EBMLFloatElement duration;
        (0x3ba9): EBMLUnicodeStringElement title;
        (0x461): EBMLDateElement dateUTC;
        (0x33a4): ByteElement segmentUUID;

        // MKV track
        (0x654ae6b): CompoundElement track;
        (0x2e): CompoundElement entry;
        (0x57): EBMLUIntElement trackNumber;
        (0x33c5): EBMLUIntElement uid;
        (0x3): EBMLUIntElement trackType;
        (0x8): EBMLUIntElement flagDefault;
        (0x1c): EBMLUIntElement flagLacing;
        (0x2de7): EBMLUIntElement minCache;
        (0x6): EBMLUIntElement codecID;
        (0x23a2): ByteElement codecPrivate;
        (0x3e383): EBMLUIntElement defaultDuration;
        (0x60): CompoundElement video;
        (0x30): EBMLUIntElement width;
        (0x3a): EBMLUIntElement height;
        (0x14b0): EBMLUIntElement displayWidth;
        (0x14ba): EBMLUIntElement displayHeight;
        (0x2b59c): EBMLASCIIStringElement language;
        (0x136e): EBMLUnicodeStringElement name;
        (0x61): CompoundElement audio;
        (0x35): EBMLFloatElement samplingFrequency;
        (0x1f): EBMLUIntElement channels;
        (0x2264): EBMLUIntElement bitdepth;

        // Cluster
        (0xf43b675): CompoundElement cluster;
        (0x67): EBMLUIntElement timestamp;
        (0x20): CompoundElement blockGroup;
        (0x23): ByteElement block;
        (0x1b): EBMLUIntElement blockDuration;
        (0x7b): EBMLIntElement referenceBlock;
        (0x27): EBMLUIntElement position;
        (0x2b): EBMLUIntElement prevSize;

        // Cueing data
        (0xc53bb6b): CompoundElement cues;
        (0x3b): CompoundElement cuePoint;
        (0x33): EBMLUIntElement cueTime;
        (0x37): CompoundElement cueTrackPosition;
        (0x77): EBMLUIntElement cueTrack;
        (0x71): EBMLUIntElement cueClusterPosition;
        (0x70): EBMLUIntElement cueRelativePosition;

        // Tagging data
        (0x254c367): CompoundElement tagging;
        (0x3373): CompoundElement tag;
        (0x23c0): CompoundElement targets;
        (0x27c8): CompoundElement simpleTag;
        (0x5a3): EBMLUnicodeStringElement name;
        (0x47a): EBMLASCIIStringElement language;
        (0x487): EBMLUnicodeStringElement value;
        (0x484): EBMLUIntElement value;
        (0x485): ByteElement value;
        (0x23c5): EBMLUIntElement trackUID;
        (0x23ca): EBMLASCIIStringElement targetType;

        (_): UnknownElement unknown;
    }
} [[inline]];

// type::Magic<"\x1a\x45\xdf\xa3"> magic @ 0x00 [[hidden]];
Element elements[while(!std::mem::eof())] @ 0x00;
