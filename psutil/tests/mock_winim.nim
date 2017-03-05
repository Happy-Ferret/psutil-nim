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
export WCHAR

export winim.`$`
export winim.`&`
export winstring_converter

proc SetErrorMode*( P1: UINT ): UINT = discard

# Functions we can use as-is
export SetLastError
export GetLastError
export FormatMessageW
export newWString
export setLen


################################################################################
var gGetDiskFreeSpaceExW_total: ULARGE_INTEGER
var gGetDiskFreeSpaceExW_free: ULARGE_INTEGER 
var gGetDiskFreeSpaceExW_result: BOOL

proc GetDiskFreeSpaceExW_return*( result: BOOL, total, free: ULARGE_INTEGER ) = 
    gGetDiskFreeSpaceExW_result = result
    gGetDiskFreeSpaceExW_total = total
    gGetDiskFreeSpaceExW_free = free

proc GetDiskFreeSpaceExW*( P1: LPCWSTR, P2: PULARGE_INTEGER, P3: PULARGE_INTEGER, P4: PULARGE_INTEGER ): BOOL =
    P3[] = gGetDiskFreeSpaceExW_total
    P4[] = gGetDiskFreeSpaceExW_free
    return gGetDiskFreeSpaceExW_result


################################################################################
var gGetLogicalDriveStringsW_P2: LPWSTR
var gGetLogicalDriveStringsW_result: DWORD

proc GetLogicalDriveStringsW_return*( result: DWORD, P2: LPWSTR ) = 
    gGetLogicalDriveStringsW_result = result
    gGetLogicalDriveStringsW_P2 = P2

proc GetLogicalDriveStringsW*( P1: DWORD, P2: LPWSTR ): DWORD = 
    copyMem( P2, gGetLogicalDriveStringsW_P2, 
             gGetLogicalDriveStringsW_result.int * sizeof(WCHAR) )
    return gGetLogicalDriveStringsW_result


################################################################################
var gGetDriveType_resultList = newSeq[UINT]()

proc GetDriveType_return*( result: UINT ) = 
    gGetDriveType_resultList.insert( result, 0 )

proc GetDriveType*( P1: LPCWSTR ): UINT = gGetDriveType_resultList.pop()


################################################################################
var gGetVolumeInformationW_result: BOOL
var gGetVolumeInformationW_P6: DWORD
var gGetVolumeInformationW_P7: LPWSTR

proc GetVolumeInformationW_return*( result: BOOL, P6: DWORD, P7: LPWSTR ) = 
    gGetVolumeInformationW_result = result
    gGetVolumeInformationW_P6 = P6
    gGetVolumeInformationW_P7 = P7

proc GetVolumeInformationW*( P1: LPCWSTR, 
                             P2: LPWSTR,
                             P3: DWORD, 
                             P4: PDWORD, 
                             P5: PDWORD, 
                             P6: PDWORD, 
                             P7: var LPWSTR, 
                             P8: DWORD ): BOOL = 
    P6[] = gGetVolumeInformationW_P6                    
    P7 = +$gGetVolumeInformationW_P7
    return gGetVolumeInformationW_result
    

################################################################################
var gEnumProcesses_result: BOOL
var gEnumProcesses_P1: seq[DWORD]
var gEnumProcesses_P3 = newSeq[DWORD]()

proc EnumProcesses_return*(result: BOOL, P1: seq[DWORD], P3: DWORD) =
    gEnumProcesses_result = result
    gEnumProcesses_P1 = P1
    gEnumProcesses_P3.insert( P3, 0 )

proc EnumProcesses*(P1: ptr DWORD, P2: DWORD, P3: ptr DWORD): BOOL =
    if gEnumProcesses_result:
        P3[] = gEnumProcesses_P3.pop()
        copyMem( P1, addr gEnumProcesses_P1[0], P3[] )
    return gEnumProcesses_result
