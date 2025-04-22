#pragma description PIF Image

/* PIF - Portable Image Format
 *
 * Basic decoder for the PIF file structure
 * https://github.com/gfcwfzkm/PIF-Image-Format
 */

#pragma MIME image/pif
#pragma endian little

import std.array;

enum imageType_t : u16 {
	RGB888 = 0x433C,
	RGB565 = 0xE5C5,
	RGB332 = 0x1E53,
	RGB16C = 0xB895,
	BLWH   = 0x7DAA,
	IND24  = 0x4952,
	IND16  = 0x4947,
	IND8   = 0x4942
};

enum compression_t : u16 {
	NO_COMPRESSION  = 0,
	RLE_COMPRESSION = 0x7DDE
};

struct PIFFileHeader {
	char  Signature[4];
	u32 FileSize;
	u32 ImageOffset;
};

struct PIFInfoHeader {
	imageType_t ImageType;
	u16 BitsPerPixel;
	u16 ImageWidth;
	u16 ImageHeight;
	u32 ImageSize;
	u16 ColorTableSize;
	compression_t Compression;
};

struct PIF {
	PIFFileHeader PIF_FileHeader;
	PIFInfoHeader PIF_ImageHeader;

	match (PIF_ImageHeader.ImageType) {
		(imageType_t::IND24): std::ByteSizedArray<u24, PIF_ImageHeader.ColorTableSize> ColorTable;
		(imageType_t::IND16): std::ByteSizedArray<u16, PIF_ImageHeader.ColorTableSize> ColorTable;
		(imageType_t::IND8): std::ByteSizedArray<u8, PIF_ImageHeader.ColorTableSize> ColorTable;
	}

	u64 ImageDataSize = PIF_FileHeader.FileSize - PIF_FileHeader.ImageOffset;
	match (PIF_ImageHeader.ImageType) {
		(imageType_t::RGB888 | imageType_t::IND24): std::ByteSizedArray<u24, ImageDataSize> ImageData;
		(imageType_t::RGB565 | imageType_t::IND16): std::ByteSizedArray<u16, ImageDataSize> ImageData;
		(imageType_t::RGB332 | imageType_t::IND8): std::ByteSizedArray<u8, ImageDataSize> ImageData;
	}
};

PIF pif @ 0x00;
