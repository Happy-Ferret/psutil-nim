import unittest

import ../psutil
import mock_winim

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
 