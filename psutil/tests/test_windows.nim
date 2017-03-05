import sequtils
import strutils
import unittest

import ../psutil
import mock_winim
import winim


################################################################################
test "Disk Partitions - GetLogicalDriveStringsW Fail":
    expect OSError:
        var drive_strings = ""
        GetLogicalDriveStringsW_return( 0, drive_strings )
        SetLastError( 3 )

        discard psutil.disk_partitions()


test "Disk Partitions - Fixed Drive Type":
    var drive_strings = "C:\\\0"
    
    GetLogicalDriveStringsW_return( DWORD(drive_strings.len), drive_strings )
    GetDriveType_return( DRIVE_FIXED )
    GetVolumeInformationW_return( True, 0, "NTFS" )

    var expected = newSeq[DiskPartition]()
    expected.add( DiskPartition( mountpoint: "C:\\",
                                 device:  "C:\\",
                                 fstype: "NTFS",
                                 opts: "rw,fixed" ) )
    
    check expected == psutil.disk_partitions()


################################################################################
test "Disk Usage":
    var total, free: ULARGE_INTEGER
    total.QuadPart = 1024
    free.QuadPart = 512
    let return_result: BOOL = 1
    GetDiskFreeSpaceExW_return( return_result, total, free )

    let expected = DiskUsage( total: total.QuadPart.int, 
                              used: int(total.QuadPart - free.QuadPart), 
                              free: free.QuadPart.int, 
                              percent: free.QuadPart.float / total.QuadPart.float * 100 )

    let result = psutil.disk_usage( "C:\\" )
    check( expected == result )
 
test "Disk Usage - Bad Path":
    expect OSError:
        var total, free: ULARGE_INTEGER
        GetDiskFreeSpaceExW_return( 0, total, free )
        SetLastError( 3 )

        discard psutil.disk_usage( "foobar" )

 
################################################################################
test "PIDs":
    var list = @[3.DWORD, 4.DWORD, 5.DWORD, 6.DWORD]
    var list_size = DWORD( list.len * sizeof(DWORD) )
    EnumProcesses_return(true, list, list_size)

    let expected = @[3,4,5,6]

    let result = psutil.pids()
    check( expected == result )

test "PIDs - 1025 pids":
    var list = repeat( 3.DWORD, 1025 )
    var list_size = DWORD( list.len * sizeof(DWORD) )
    EnumProcesses_return(true, list, 1024*sizeof(DWORD))
    EnumProcesses_return(true, list, list_size)

    let expected = repeat( 3, 1025 )

    let result = psutil.pids()
    check( expected == result )

test "PIDs - EnumProcesses Failure":
    expect OSError:
        EnumProcesses_return(false, nil, 0)
        discard psutil.pids()

 
################################################################################
test "Virtual Memory":
    var memInfo: MEMORYSTATUSEX
    memInfo.dwLength = sizeof(MEMORYSTATUSEX).DWORD
    memInfo.ullTotalPhys = 2048
    memInfo.ullAvailPhys = 2048-512
    GlobalMemoryStatusEx_return(1, meminfo)

    let expected = VirtualMemory( total: 2048,      
                                  avail: 2048-512,      
                                  percent: 25.0,  
                                  used: 512,
                                  free: 2048-512 )

    let result = psutil.virtual_memory()
    check( expected == result )
