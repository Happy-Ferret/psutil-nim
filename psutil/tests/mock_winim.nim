import winim

export BOOL
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
export FORMAT_MESSAGE_IGNORE_INSERTS
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

proc GetDriveType*(P1: LPCWSTR): UINT = discard
proc GetVolumeInformationW*(P1: LPCWSTR, P2: LPWSTR, P3: DWORD, P4: PDWORD, P5: PDWORD, P6: PDWORD, P7: LPWSTR, P8: DWORD): BOOL = discard
proc SetErrorMode*(P1: UINT): UINT = discard

# Functions we can use as-is
export SetLastError
export GetLastError
export FormatMessageW

################################################################################
var gGetDiskFreeSpaceExW_total: ULARGE_INTEGER
var gGetDiskFreeSpaceExW_free: ULARGE_INTEGER 
var gGetDiskFreeSpaceExW_result: BOOL

proc GetDiskFreeSpaceExW_return*( result: BOOL, total, free: ULARGE_INTEGER ) = 
    gGetDiskFreeSpaceExW_result = result
    gGetDiskFreeSpaceExW_total = total
    gGetDiskFreeSpaceExW_free = free

proc GetDiskFreeSpaceExW*(P1: LPCWSTR, P2: PULARGE_INTEGER, P3: PULARGE_INTEGER, P4: PULARGE_INTEGER): BOOL =
    P3[] = gGetDiskFreeSpaceExW_total
    P4[] = gGetDiskFreeSpaceExW_free
    return gGetDiskFreeSpaceExW_result


################################################################################
var gGetDiskFreeSpaceExW_P2: LPWSTR
var gGetLogicalDriveStringsW_result: DWORD

proc GetLogicalDriveStringsW_return*( result: DWORD, P2: LPWSTR ) = 
    gGetLogicalDriveStringsW_result = result
    gGetDiskFreeSpaceExW_P2 = P2

proc GetLogicalDriveStringsW*(P1: DWORD, P2: LPWSTR): DWORD = 
    P2[] = gGetDiskFreeSpaceExW_P2[]
    return gGetLogicalDriveStringsW_result
