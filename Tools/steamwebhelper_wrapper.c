/**
 * steamwebhelper_wrapper.c
 *
 * Replaces steamwebhelper.exe in the Steam CEF directory.
 * Injects --no-sandbox into every CEF subprocess call so the GPU/renderer
 * processes can initialise under Wine without kernel-level sandboxing.
 *
 * Install steps (done by Barrel automatically):
 *   1. Rename steamwebhelper.exe  →  steamwebhelper_real.exe
 *   2. Copy this compiled wrapper  →  steamwebhelper.exe
 *
 * Compile:
 *   x86_64-w64-mingw32-gcc -O2 -mwindows -o steamwebhelper_wrapper.exe steamwebhelper_wrapper.c
 */

#include <windows.h>
#include <string.h>
#include <stdio.h>

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrev, LPSTR lpCmdLine, int nShow)
{
    /* Directory that contains this wrapper (= CEF dir) */
    char selfDir[MAX_PATH];
    GetModuleFileNameA(NULL, selfDir, MAX_PATH);
    char *slash = strrchr(selfDir, '\\');
    if (slash) *slash = '\0';

    /* Path to the real steamwebhelper */
    char realExe[MAX_PATH];
    _snprintf(realExe, MAX_PATH, "%s\\steamwebhelper_real.exe", selfDir);

    /* Build new command line:
       --no-sandbox  : disables CEF kernel sandboxing (required under Wine)
       --disable-gpu : prevents GPU process from spawning (D3D/Metal fails under Wine)
       --disable-gpu-sandbox : belt-and-suspenders GPU sandbox bypass            */
    char cmdLine[65536];
    if (lpCmdLine && lpCmdLine[0]) {
        _snprintf(cmdLine, sizeof(cmdLine),
                  "\"%s\" --no-sandbox --disable-gpu --disable-gpu-sandbox %s",
                  realExe, lpCmdLine);
    } else {
        _snprintf(cmdLine, sizeof(cmdLine),
                  "\"%s\" --no-sandbox --disable-gpu --disable-gpu-sandbox",
                  realExe);
    }

    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    ZeroMemory(&pi, sizeof(pi));
    si.cb = sizeof(si);

    if (!CreateProcessA(
            NULL,       /* use cmdLine for exe path */
            cmdLine,
            NULL, NULL,
            TRUE,       /* inherit handles — keeps CEF pipes intact */
            0,
            NULL, NULL,
            &si, &pi))
    {
        return (int)GetLastError();
    }

    WaitForSingleObject(pi.hProcess, INFINITE);

    DWORD exitCode = 1;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return (int)exitCode;
}
