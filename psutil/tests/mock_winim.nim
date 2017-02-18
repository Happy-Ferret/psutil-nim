import winim

export DRIVE_CDROM
export DRIVE_FIXED
export DRIVE_NO_ROOT_DIR
export DRIVE_RAMDISK
export DRIVE_REMOTE
export DRIVE_REMOVABLE
export DRIVE_UNKNOWN
export DWORD
export FILE_READ_ONLY_VOLUME
export FILE_VOLUME_IS_COMPRESSED
export FORMAT_MESSAGE_FROM_SYSTEM
export LANG_NEUTRAL
export LPCWSTR
export LPWSTR
export MAKELANGID
export NULL
export SEM_FAILCRITICALERRORS
export SUBLANG_DEFAULT
export ULARGE_INTEGER
export WORD

export winim.`$`
export winim.`&`
export winstring_converter

proc FormatMessageW*(P1: DWORD, P2: PCVOID, P3: DWORD, P4: DWORD, P5: LPWSTR, P6: DWORD, P7: ptr va_list): DWORD = discard
proc GetDriveType*(P1: LPCWSTR): UINT = discard
proc GetLastError*(): DWORD = discard
proc GetLogicalDriveStringsW*(P1: DWORD, P2: LPWSTR): DWORD = discard
proc GetVolumeInformationW*(P1: LPCWSTR, P2: LPWSTR, P3: DWORD, P4: PDWORD, P5: PDWORD, P6: PDWORD, P7: LPWSTR, P8: DWORD): BOOL = discard
proc SetErrorMode*(P1: UINT): UINT = discard
proc SetLastError*(P1: DWORD): void = discard



proc GetDiskFreeSpaceExW*(P1: LPCWSTR, P2: PULARGE_INTEGER, P3: PULARGE_INTEGER, P4: PULARGE_INTEGER): BOOL =
    discard
