# https://gist.github.com/letmaik/d650ee257a27df8eac0f71f17aa99765
function CartesianProduct {
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Hashtable]
        $values = @{ Foo = 1..5; Bar = 1..10}
    )
    $keys = @($values.GetEnumerator() | ForEach-Object { $_.Name })
    $result = @($values[$keys[0]] | ForEach-Object { @{ $keys[0] = $_ } })
    if ($keys.Length -gt 1) {
        foreach ($key in $keys[1..($keys.Length - 1)]) {
            $result = foreach ($entry in $result) {
                foreach ($value in $values[$key]) {
                    $entry + @{ $key = $value }
                }
            }
        }
    }
    $result
}

$InstanceName = "localhost"
$DatabaseName = "StackOverflowTiny"

foreach ($entry in CartesianProduct @{ BlockSize = (0.5kb, 1kb, 2kb, 4kb, 8kb, 16kb, 32kb, 64kb); BufferCount = (7, 15, 30, 60, 128, 256, 512, 1024); MaxTransferSize = (64kb, 128kb, 256kb, 512kb, 1mb, 2mb, 4mb); FileCount = (1, 2, 4, 6, 8, 10, 12) }) {
  # Sample:  3136 (8 * 8 * 7 * 7) possible entries. Let's get ~100 samples per database, so 3% of the total samples.
  $rand = Get-Random -Maximum 100
  # We are making a fair assumption that Get-Random is a uniformly distributed pseudo-random number generator.  Setting -Maximum 100 means we'll get a range from 0-99.
  if ($rand -gt 96) {
    $outcome = Backup-DbaDatabase -SqlInstance ($InstanceName) -BackupDirectory C:\temp\BackupFiles -Database ($DatabaseName) -Type Full -CopyOnly -CompressBackup -BufferCount ($entry.BufferCount) -FileCount ($entry.FileCount)
  "$($entry.BlockSize),$($entry.Buffercount),$($entry.MaxTransferSize),$($entry.FileCount),$($outcome.Duration.TotalSeconds)" >> C:\Temp\PerfTest.txt
    Remove-Item C:\Temp\BackupFiles\*
  }
}