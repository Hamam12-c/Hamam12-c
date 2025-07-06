void AmsiScan(undefined8 contents,undefined4 contentLength) {
  int hr;
  HMODULE hModule;
  bool bVar2;
  uint amsiResult [2];
  longlong pAmsiContext;
  longlong local_48;
  uint local_40;
  undefined2 *local_38;
  longlong lVar1;
  
  lVar1 = DAT_180913798;
  local_48 = DAT_180913798;
  local_40 = 0;
  bVar2 = DAT_180913798 != 0;
  if (bVar2) {
    FUN_180156b78(DAT_180913798);
  }
  local_40 = (uint)bVar2;
  if ((global_pAmsiContext == 0) && (g_amsiInitializationAttempted == '\0')) {
    hr = FUN_1800e71e8();
    if ((hr != 0) &&
       ((hModule = (HMODULE)CLRLoadLibraryEx(L"amsi.dll",0,0x800), hModule != (HMODULE)0x0 &&
        (_global_pAmsiInitialize = GetProcAddress(hModule,"AmsiInitialize"),
        _global_pAmsiInitialize != (FARPROC)0x0)))) {
      pAmsiContext = 0;
      hr = (*_global_pAmsiInitialize)(L"DotNet",&pAmsiContext);
      if ((hr == 0) &&
         (global_AmsiScanBuffer = GetProcAddress(hModule,"AmsiScanBuffer"),
         global_AmsiScanBuffer != (FARPROC)0x0)) {
        global_pAmsiContext = pAmsiContext;
      }
    }
    g_amsiInitializationAttempted = '\x01';
  }
  if (bVar2) {
    FUN_180084d70(lVar1);
    local_40 = 0;
  }
  if (((global_pAmsiContext != 0) &&
      (hr = (*global_AmsiScanBuffer)(global_pAmsiContext,contents,contentLength,0,0,amsiResult),
      hr == 0)) && ((0x7fff < amsiResult[0] || (amsiResult[0] - 0x4000 < 0x1000)))) {
                    /* This code is only run if the AmsiScanBuffer call was successful and the AV
                       identified the contents as malicious */
    local_48 = 0x200000002;
    local_40 = 0x10;
    local_38 = &DAT_180769d3c;
    FUN_1805fc338(0x800700e1,&local_48,0);
    FUN_1805fdd0c(&DAT_8007000b,&local_48);
  }
  return;
}
