{.deadCodeElim: on.}

import strutils
import tables

when not defined testing:
    import winim
else:
    import tests/mock_winim as winim

import common

var AF_PACKET* = -1


proc pid_exists*( pid: int ): bool = discard
proc cpu_count_logical*(): int = discard
proc cpu_count_physical*(): int = discard
proc cpu_times*(): CPUTimes = discard
proc per_cpu_times*(): seq[CPUTimes] = discard
proc virtual_memory*(): VirtualMemory = discard
proc per_nic_net_io_counters*(): TableRef[string, NetIO] = newTable[string, NetIO]()
proc per_disk_io_counters*(): TableRef[string, DiskIO] = discard
proc net_if_addrs*(): Table[string, seq[common.Address]] = discard
proc boot_time*(): float = discard
proc users*(): seq[User] = discard
proc cpu_stats*(): tuple[ctx_switches, interrupts, soft_interrupts, syscalls: int] = discard
proc swap_memory*(): SwapMemory = discard
proc net_if_stats*(): TableRef[string, NICstats] = discard
proc net_connections*( kind= "inet", pid= -1 ): seq[Connection] = discard


proc raiseError() = 
    var error_message: LPWSTR = newStringOfCap( 256 )
    let error_code = GetLastError()
    discard FormatMessageW( FORMAT_MESSAGE_FROM_SYSTEM, 
                            NULL, 
                            error_code,
                            MAKELANGID( LANG_NEUTRAL, SUBLANG_DEFAULT ),
                            error_message, 
                            256, 
                            NULL )
    discard SetErrorMode( 0 )
    raise newException( OSError, "ERROR ($1): $2" % [$error_code, $error_message] )


proc psutil_get_drive_type( drive_type: uint ): string =
    case drive_type
        of DRIVE_FIXED: "fixed"
        of DRIVE_CDROM: "cdrom"
        of DRIVE_REMOVABLE: "removable"
        of DRIVE_UNKNOWN: "unknown"
        of DRIVE_NO_ROOT_DIR: "unmounted"
        of DRIVE_REMOTE: "remote"
        of DRIVE_RAMDISK: "ramdisk"
        else: "?"


proc pids*(): seq[int] = 
    ## Returns a list of PIDs currently running on the system.
    result = newSeq[int]()

    var procArray: seq[DWORD]
    var procArrayLen = 0
    # Stores the byte size of the returned array from enumprocesses
    var enumReturnSz: DWORD = 0

    while enumReturnSz == DWORD( procArrayLen * sizeof(DWORD) ):
        procArrayLen += 1024
        procArray = newSeq[DWORD](procArrayLen)

        if EnumProcesses( addr procArray[0], 
                          DWORD( procArrayLen * sizeof(DWORD) ), 
                          &enumReturnSz ) == 0:
            raiseError()
            return result

    # The number of elements is the returned size / size of each element
    let numberOfReturnedPIDs = int( int(enumReturnSz) / sizeof(DWORD) )
    for i in 0..<numberOfReturnedPIDs:
        result.add( procArray[i].int )


proc disk_partitions*( all=false ): seq[DiskPartition] =
    result = newSeq[DiskPartition]()

    # avoid to visualize a message box in case something goes wrong
    # see https://github.com/giampaolo/psutil/issues/264
    discard SetErrorMode( SEM_FAILCRITICALERRORS )
    
    var drive_strings = newWString( 256 )
    let returned_len = GetLogicalDriveStringsW( 256, &drive_strings )
    if returned_len == 0:
        raiseError()
        return
    
    let letters = split( strip( $drive_strings, chars={'\0'} ), '\0' )
    for drive_letter in letters:
        let drive_type = GetDriveType( drive_letter )

        # by default we only show hard drives and cd-roms
        if not all:
            if drive_type == DRIVE_UNKNOWN or
               drive_type == DRIVE_NO_ROOT_DIR or
               drive_type == DRIVE_REMOTE or
               drive_type == DRIVE_RAMDISK: continue

            # floppy disk: skip it by default as it introduces a considerable slowdown.
            if drive_type == DRIVE_REMOVABLE and drive_letter == "A:\\":
                continue


        var fs_type: LPWSTR = newString( 256 )
        var pflags: DWORD = 0
        var lpdl: LPCWSTR = drive_letter
        let gvi_ret = GetVolumeInformationW( lpdl,
                                             NULL,
                                             DWORD( drive_letter.len ),
                                             NULL,
                                             NULL,
                                             &pflags,
                                             fs_type,
                                             DWORD( 256 ) )
        var opts = ""
        if gvi_ret == 0:
            # We might get here in case of a floppy hard drive, in
            # which case the error is ( 21, "device not ready").
            # Let's pretend it didn't happen as we already have
            # the drive name and type ('removable').
            SetLastError( 0 )
        else:
            opts = if ( pflags and FILE_READ_ONLY_VOLUME ) != 0: "ro" else: "rw"
            
            if ( pflags and FILE_VOLUME_IS_COMPRESSED ) != 0:
                opts &= ",compressed"
                    
        if len( opts ) > 0:
            opts &= ","
        opts &= psutil_get_drive_type( drive_type )
        
        result.add( DiskPartition( mountpoint: drive_letter,
                                   device: drive_letter,
                                   fstype: $fs_type, # either FAT, FAT32, NTFS, HPFS, CDFS, UDF or NWFS
                                   opts: opts ) )
        discard SetErrorMode( 0 )


proc disk_usage*( path: string ): DiskUsage =
    ## Return disk usage associated with path.
    var total, free: ULARGE_INTEGER
    
    let ret_code = GetDiskFreeSpaceExW( path, nil, &total, &free )
    if ret_code != 1: raiseError()

    let used = total.QuadPart - free.QuadPart
    let percent = usage_percent( used.int, total.QuadPart.int, places=1 )
    return DiskUsage( total:total.QuadPart.int, used:used.int,
                      free:free.QuadPart.int, percent:percent )
