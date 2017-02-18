{.deadCodeElim: on.}

import strutils
import tables

when not defined(testing):
    import winim
else:
    import tests/mock_winim as winim

import common

var AF_PACKET* = -1

proc pids*(): seq[int] = discard
proc pid_exists*( pid: int ): bool = discard
proc cpu_count_logical*(): int = discard
proc cpu_count_physical*(): int = discard
proc cpu_times*(): CPUTimes = discard
proc per_cpu_times*(): seq[CPUTimes] = discard
proc virtual_memory*(): VirtualMemory = discard
proc per_nic_net_io_counters*(): TableRef[string, NetIO] = discard
proc per_disk_io_counters*(): TableRef[string, DiskIO] = discard
proc net_if_addrs*(): Table[string, seq[common.Address]] = discard
proc boot_time*(): float = discard
proc users*(): seq[User] = discard
proc cpu_stats*(): tuple[ctx_switches, interrupts, soft_interrupts, syscalls: int] = discard
proc swap_memory*(): SwapMemory = discard
proc net_if_stats*(): TableRef[string, NICstats] = discard
proc net_connections*( kind= "inet", pid= -1 ): seq[Connection] = discard

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

proc disk_partitions*(all=false): seq[DiskPartition] =
    result = newSeq[DiskPartition]()

    # avoid to visualize a message box in case something goes wrong
    # see https://github.com/giampaolo/psutil/issues/264
    discard SetErrorMode(SEM_FAILCRITICALERRORS)
    
    var drive_strings: LPWSTR = newString( 256 )
    let num_bytes = GetLogicalDriveStringsW(256, drive_strings)
    if num_bytes == 0:
        var error_message: LPWSTR = newStringOfCap(256)
        discard FormatMessageW( FORMAT_MESSAGE_FROM_SYSTEM, NULL, GetLastError(),
                        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                        error_message, 256, NULL);
        echo "ERROR: GetLogicalDriveStrings - ", error_message
        discard SetErrorMode(0);
        return

    let letters = ($drive_strings).split('\0')
    for drive_letter in letters:
        let drive_type = GetDriveType( drive_letter )

        # by default we only show hard drives and cd-roms
        if not all:
            if ( drive_type == DRIVE_UNKNOWN or
                 drive_type == DRIVE_NO_ROOT_DIR or
                 drive_type == DRIVE_REMOTE or
                 drive_type == DRIVE_RAMDISK ): continue

            # floppy disk: skip it by default as it introduces a considerable slowdown.
            if drive_type == DRIVE_REMOVABLE and drive_letter == "A:\\":
                continue


        var fs_type: LPWSTR = newString( 256 )
        var pflags: DWORD = 0
        var lpdl: LPCWSTR = drive_letter
        let gvi_ret = GetVolumeInformationW( lpdl,
                                             NULL,
                                             DWORD(drive_letter.len),
                                             NULL,
                                             NULL,
                                             &pflags,
                                             fs_type,
                                             DWORD(256) )
        var opts = ""
        if gvi_ret == 0:
            # We might get here in case of a floppy hard drive, in
            # which case the error is (21, "device not ready").
            # Let's pretend it didn't happen as we already have
            # the drive name and type ('removable').
            SetLastError(0);
        else:
            opts = if (pflags and FILE_READ_ONLY_VOLUME) != 0: "ro" else: "rw"
            
            if (pflags and FILE_VOLUME_IS_COMPRESSED) != 0:
                opts &= ",compressed"
                    
        if len(opts) > 0:
            opts &= ","
        opts &= psutil_get_drive_type( drive_type )
        
        result.add( DiskPartition( mountpoint: drive_letter,
                                   device: drive_letter,
                                   fstype: $fs_type, # either FAT, FAT32, NTFS, HPFS, CDFS, UDF or NWFS
                                   opts: opts ) )
        discard SetErrorMode(0)

proc disk_usage*( path: string ): DiskUsage =
    ## Return disk usage associated with path.
    var total, free: ULARGE_INTEGER
    discard GetDiskFreeSpaceExW( path, nil, &total, &free )
    let used = total.QuadPart - free.QuadPart
    let percent = usage_percent( used.int, total.QuadPart.int, places=1 )
    return DiskUsage( total:total.QuadPart.int, used:used.int,
                      free:free.QuadPart.int, percent:percent )
