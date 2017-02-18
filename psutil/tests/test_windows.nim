import unittest

import ../psutil

test "Disk Usage":
    let expected = DiskUsage()

    let result = psutil.disk_usage( "C:/" )
    check( expected == result )
 