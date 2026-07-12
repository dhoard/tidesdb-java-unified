package com.tidesdb;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledOnOs;
import org.junit.jupiter.api.condition.OS;

class NativeLibraryTest {

    @Test
    void normalizeOsLinux() {
        assertEquals("linux", NativeLibrary.normalizeOs("Linux"));
        assertEquals("linux", NativeLibrary.normalizeOs("LINUX"));
        assertEquals("linux", NativeLibrary.normalizeOs("GNU/Linux"));
    }

    @Test
    void normalizeOsMacos() {
        assertEquals("macos", NativeLibrary.normalizeOs("Mac OS X"));
        assertEquals("macos", NativeLibrary.normalizeOs("Darwin"));
        assertEquals("macos", NativeLibrary.normalizeOs("macOS"));
    }

    @Test
    void normalizeOsWindows() {
        assertEquals("windows", NativeLibrary.normalizeOs("Windows 10"));
        assertEquals("windows", NativeLibrary.normalizeOs("Windows NT"));
    }

    @Test
    void normalizeOsUnsupported() {
        assertThrows(UnsatisfiedLinkError.class, () -> NativeLibrary.normalizeOs("FreeBSD"));
    }

    @Test
    void normalizeArchX86_64() {
        assertEquals("x86_64", NativeLibrary.normalizeArch("amd64"));
        assertEquals("x86_64", NativeLibrary.normalizeArch("x86_64"));
        assertEquals("x86_64", NativeLibrary.normalizeArch("x64"));
    }

    @Test
    void normalizeArchAarch64() {
        assertEquals("aarch64", NativeLibrary.normalizeArch("aarch64"));
        assertEquals("aarch64", NativeLibrary.normalizeArch("arm64"));
    }

    @Test
    void normalizeArchUnsupported() {
        assertThrows(UnsatisfiedLinkError.class, () -> NativeLibrary.normalizeArch("ppc64le"));
    }

    @Test
    void mapLibraryNameLinux() {
        assertEquals("libtidesdb_jni.so", NativeLibrary.mapLibraryName("linux"));
    }

    @Test
    void mapLibraryNameMacos() {
        assertEquals("libtidesdb_jni.dylib", NativeLibrary.mapLibraryName("macos"));
    }

    @Test
    void mapLibraryNameWindows() {
        assertEquals("tidesdb_jni.dll", NativeLibrary.mapLibraryName("windows"));
    }

    @Test
    @EnabledOnOs(OS.LINUX)
    void loadShouldSucceedOnLinux() {
        NativeLibrary.load();
        assertTrue(NativeLibrary.isLoaded());
    }

    @Test
    void loadShouldBeIdempotent() {
        NativeLibrary.load();
        NativeLibrary.load();
        NativeLibrary.load();
        assertTrue(NativeLibrary.isLoaded());
    }

    @Test
    void loadConcurrently() throws Exception {
        int threads = 10;
        Thread[] ts = new Thread[threads];
        for (int i = 0; i < threads; i++) {
            ts[i] = new Thread(NativeLibrary::load);
        }
        for (Thread t : ts) t.start();
        for (Thread t : ts) t.join();
        assertTrue(NativeLibrary.isLoaded());
    }
}
