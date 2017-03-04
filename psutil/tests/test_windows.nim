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
    var drive_strings = "C:\\"
    
    GetLogicalDriveStringsW_return( drive_strings.len.DWORD, drive_strings )
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

 