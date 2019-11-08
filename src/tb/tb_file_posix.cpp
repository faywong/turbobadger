// ================================================================================
// ==      This file is a part of Turbo Badger. (C) 2011-2014, Emil Segerås      ==
// ==                     See tb_core.h for more information.                    ==
// ================================================================================

#include "tb_system.h"

#ifdef TB_FILE_POSIX

#include <stdio.h>

namespace tb {

class TBPosixFile : public TBFile
{
public:
	TBPosixFile(FILE *f) : file(f) {}
	virtual ~TBPosixFile() { fclose(file); }

	virtual long Size()
	{
		long oldpos = ftell(file);
		fseek(file, 0, SEEK_END);
		long num_bytes = ftell(file);
		fseek(file, oldpos, SEEK_SET);
		return num_bytes;
	}
	virtual size_t Read(void *buf, size_t elemSize, size_t count)
	{
		return fread(buf, elemSize, count, file);
	}
	virtual size_t Write(const void *buf, size_t elemSize, size_t count)
	{
		return fwrite(buf, elemSize, count, file);
	}
	virtual size_t Write(const TBStr & str)
	{
		return Write(str.CStr(), 1, str.Length());
	}
private:
	FILE *file;
};

// static
TBFile *TBFile::Open(const TBStr & filename, TBFileMode mode)
{
	FILE *f = nullptr;
	TBStr pathfile;
	if (filename[0] != '/')
	{
#ifdef TB_FILE_POSIX_PREFIX
		pathfile.Set(TB_FILE_POSIX_PREFIX);
#endif
		pathfile.Append(filename);
	}
	else
		pathfile.Set(filename);
	switch (mode)
	{
	case MODE_READ:
		f = fopen(pathfile.CStr(), "rb");
		break;
	case MODE_WRITETRUNC:
		f = fopen(pathfile.CStr(), "w");
		break;
	default:
		break;
	}
#if defined(TB_RUNTIME_DEBUG_INFO) && 1
	if (!f)
		TBDebugPrint("TBFile::Open, unable to open file '%s'\n", pathfile.CStr());
#endif
	if (!f)
		return nullptr;
	TBPosixFile *tbf = new TBPosixFile(f);
	if (!tbf)
		fclose(f);
	return tbf;
}

} // namespace tb

#endif // TB_FILE_POSIX
