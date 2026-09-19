<!--
  ╔══════════════════════════════════════════════════════════════════════╗
  ║   🌌 PROJECT GENESIS — RESOLUTION MASTER ENGINE (RME)              ║
  ║   Official Companion to The Milky Way Equation                     ║
  ║   Public Release 1.0.0 · GitHub Ready                              ║
  ╚══════════════════════════════════════════════════════════════════════╝
-->

<div align="center">

# 🌌 RESOLUTION MASTER ENGINE (RME)
## Universal Display Pipeline & Proportional DPI Downscale Engine

**Official Companion Series to Project Genesis — The Milky Way Equation**

**INFINIX · TECNO · ITEL · ALL ANDROID**

---

[![Platform](https://img.shields.io/badge/Platform-Android%2011--16-green?style=flat-square&logo=android)](https://github.com)
[![Mode](https://img.shields.io/badge/Mode-No%20Root%20%7C%20ADB%20%7C%20Shizuku-blue?style=flat-square)](https://github.com)
[![Safety](https://img.shields.io/badge/Safety-30s%20Watchdog-orange?style=flat-square)](https://github.com)
[![Author](https://img.shields.io/badge/By-Aceng%20D%20Monk-purple?style=flat-square)](https://github.com)
[![Version](https://img.shields.io/badge/Version-v1.0.0%20Public%20Release-red?style=flat-square)](https://github.com)

<br>

### 👇 **QUICK ACTIONS / JALAN PINTAS** 👇

[![Download Script](https://img.shields.io/badge/📥_DOWNLOAD_SCRIPT-Raw_File-2ea44f?style=for-the-badge)](https://github.com/AcengDMonk/Resolution-Master-Engine/releases)
[![View Protocol](https://img.shields.io/badge/📜_MILKYWAY_PROTOCOL-Companion-blue?style=for-the-badge)](https://gist.github.com/AcengDMonk)

<br>

*Use this file as the official documentation for Resolution Master Engine.*  
*Gunakan file ini sebagai dokumentasi resmi Resolution Master Engine.*

</div>

---

## 📋 Table of Contents / Daftar Isi

| # | Section | EN Summary | Ringkasan ID |
|---|---------|------------|--------------|
| 1 | [Project Identity](#-1--project-identity--identitas-proyek) | What RME is & how it works | Apa RME & cara kerjanya |
| 2 | [Preset Matrix](#-2--preset-matrix--matrix-preset) | Golden / Performance / Extreme | Matrix resolusi optimal |
| 3 | [User Configuration](#-3--user-configuration--konfigurasi-pengguna) | SECTION 0 variables | Variabel SECTION 0 |
| 4 | [Safety Watchdog](#-4--safety-watchdog--sistem-pengaman) | 30-second auto-rollback | Auto-rollback 30 detik |
| 5 | [How to Run](#-5--how-to-run--cara-menjalankan) | ADB / Shizuku / Root | Instalasi & eksekusi |
| 6 | [Command Reference](#-6--command-reference--referensi-perintah) | Full CLI commands | Daftar perintah lengkap |
| 7 | [Transsion Sync](#-7--transsion-sync--sinkronisasi-xos) | XOS/HiOS database coupling | Sinkronisasi database vendor |
| 8 | [Risk & DWYOR](#-8--risk--dwyor--risiko) | Safety levels | Level risiko |
| 9 | [Quick Reset](#-9--quick-reset--perintah-reset) | Restore native resolution | Kembalikan resolusi native |
| 10 | [Changelog](#-10--changelog--riwayat-versi) | Version history | Riwayat versi |

---

## 🌌 1 · Project Identity / Identitas Proyek

> **EN** — Resolution Master Engine (RME) is a **low-level, pure POSIX shell** display scaler for Android.  
> It dynamically downscales resolution + DPI while preserving aspect ratio and physical UI size (sw dp).  
> Companion to **Project Genesis — The Milky Way Equation**.
>
> **ID** — Resolution Master Engine (RME) adalah **mesin penskalaan layar low-level berbasis Shell POSIX murni** untuk Android.  
> Ia menurunkan resolusi + DPI secara dinamis sambil menjaga rasio aspek dan ukuran fisik antarmuka (sw dp).  
> Pendamping resmi **Project Genesis — The Milky Way Equation**.

<details>
<summary><b>📖 Read more / Baca selengkapnya</b></summary>

### EN — Full Description

RME runs **WITHOUT ROOT** via ADB, Shizuku, LADB, aShell, or Termux.  
It uses only standard Android WindowManager (`wm size` / `wm density`) + optional Transsion system database sync.

**Core philosophy:**
- Fill-rate GPU headroom maximization
- Proportional DPI (diagonal Pythagorean formula)
- Strict aspect-ratio enforcement
- 30-second Safety Watchdog against black screen / soft-brick

**Primary targets:**
- Transsion Group (Infinix · Tecno · Itel) — XOS / HiOS
- MediaTek Helio G99 / G200 / Dimensity 7xxx / 9xxx
- Universal fallback for any Android 11–16 device

---

### ID — Deskripsi Lengkap

RME berjalan **TANPA ROOT** melalui ADB, Shizuku, LADB, aShell, atau Termux.  
Hanya menggunakan perintah Android standar WindowManager (`wm size` / `wm density`) + sinkronisasi database sistem Transsion (opsional).

**Filosofi inti:**
- Maksimalkan headroom fill-rate GPU
- DPI proporsional (rumus diagonal Pythagorean)
- Penegakan rasio aspek ketat
- Safety Watchdog 30 detik untuk mencegah black screen / soft-brick

**Target utama:**
- Transsion Group (Infinix · Tecno · Itel) — XOS / HiOS
- MediaTek Helio G99 / G200 / Dimensity 7xxx / 9xxx
- Fallback universal untuk semua perangkat Android 11–16

</details>

---

## 📊 2 · Preset Matrix / Matrix Preset

> **EN** — Specialized profile for Infinix Note 50 Pro (1080×2436 @ 440 DPI).  
> Universal Dynamic Engine activates automatically on other devices.
>
> **ID** — Profil khusus untuk Infinix Note 50 Pro (1080×2436 @ 440 DPI).  
> Universal Dynamic Engine aktif otomatis di perangkat lain.

### Specialized Profile — Infinix Note 50 Pro

| Profil | Resolusi Target | DPI | Skala Linear | Pengurangan Piksel | Beban GPU | Karakteristik Visual |
|:-------|:---------------:|:---:|:------------:|:------------------:|:---------:|:---------------------|
| **Native (Bawaan)** | $1080 \times 2436$ | `440` | 100.0% | $0\%$ | 100% | Resolusi fisik pabrik |
| **GOLDEN** ⭐ | $\mathbf{720 \times 1624}$ | $\mathbf{293}$ | **66.7%** | **-55.6%** | **Sangat Ringan** | **Rekomendasi Utama.** Tajam, stabil, dingin |
| **PERFORMANCE** | $756 \times 1705$ | `308` | 70.0% | -51.0% | Ringan | Downscale moderat harian |
| **EXTREME** | $540 \times 1218$ | `220` | 50.0% | -75.0% | Minimal | Turnamen (PUBG / Genshin / MLBB) |

> 🌐 **Universal Dynamic Engine**  
> On non-1080×2436 devices the script calculates pure aspect ratio and applies the same scale factor (66.7% / 70% / 50%) while keeping **smallestWidth (sw) ≈ constant**.

---

## 🎛️ 3 · User Configuration / Konfigurasi Pengguna

> **EN** — Edit **only** `SECTION 0`. Everything below is engine internals.
>
> **ID** — Hanya edit **SECTION 0**. Semua di bawah adalah mesin internal.

```sh
# [A] Default Preset (when run without arguments)
DEFAULT_PRESET="GOLDEN"          # GOLDEN | PERFORMANCE | EXTREME | NATIVE

# [B] Execution Mode
DEFAULT_EXEC_MODE="PREVIEW"      # PREVIEW (safe 30s) | INSTANT (no watchdog)

# [C] Watchdog Timeout
PREVIEW_SECONDS=30

# [D] Transsion XOS / HiOS System Sync
SYNC_TRANSSION_XOS=1             # 1 = sync vendor database + hwc buffer
                                 # 0 = pure AOSP wm commands only
```

| Variable | Safe Default | Description EN | Deskripsi ID |
|----------|:------------:|----------------|--------------|
| `DEFAULT_PRESET` | `GOLDEN` | Recommended everyday gaming profile | Profil gaming harian yang direkomendasikan |
| `DEFAULT_EXEC_MODE` | `PREVIEW` | Always use PREVIEW unless automated | Selalu gunakan PREVIEW kecuali otomatisasi |
| `PREVIEW_SECONDS` | `30` | Auto-rollback window | Jendela auto-rollback |
| `SYNC_TRANSSION_XOS` | `1` | Keep Transsion display settings in sync | Jaga sinkronisasi pengaturan layar Transsion |

---

## 🛡️ 4 · Safety Watchdog / Sistem Pengaman

> **EN** — Every preview is protected by a 30-second independent guard process.  
> If you do not confirm, the display automatically reverts to the previous state.  
> **Zero risk of permanent black screen or soft-brick.**
>
> **ID** — Setiap preview dilindungi oleh proses guard independen 30 detik.  
> Jika tidak dikonfirmasi, layar otomatis kembali ke kondisi sebelumnya.  
> **Nol risiko black screen permanen atau soft-brick.**

### How the Watchdog Works / Cara Kerja Watchdog

1. Script writes pending state + unique token
2. Spawns background `guard` process
3. Applies new resolution via `wm size` + `wm density`
4. Starts 30-second countdown
5. User must run `confirm <token>` to lock
6. On timeout / failure → automatic rollback

---

## 🛠️ 5 · How to Run / Cara Menjalankan

### Prerequisites / Persyaratan

1. Enable **Developer Options**
2. Enable **USB Debugging** + **Wireless Debugging**
3. (Optional) Enable **Disable Permission Monitoring**

### Installation (No Root)

```bash
# Copy to executable location (sdcard is noexec)
cp /sdcard/Download/Resolution-Master-Engine.sh /data/local/tmp/
chmod +x /data/local/tmp/Resolution-Master-Engine.sh
```

### Execution Methods

| Method | Command |
|--------|---------|
| **ADB (PC)** | `adb shell sh /data/local/tmp/Resolution-Master-Engine.sh` |
| **Shizuku / aShell** | `sh /data/local/tmp/Resolution-Master-Engine.sh` |
| **LADB / Termux** | same as above |
| **Root** | same (UID 0 also supported) |

> ⚠️ Always run from `/data/local/tmp/` — `/sdcard` has `noexec` flag.

---

## 📜 6 · Command Reference / Referensi Perintah

```bash
# Apply recommended Golden profile (preview mode)
sh /data/local/tmp/Resolution-Master-Engine.sh auto
# or
sh /data/local/tmp/Resolution-Master-Engine.sh golden

# Other presets
sh /data/local/tmp/Resolution-Master-Engine.sh performance
sh /data/local/tmp/Resolution-Master-Engine.sh extreme

# Instant apply (no 30s watchdog) — use with caution
sh /data/local/tmp/Resolution-Master-Engine.sh instant

# Custom resolution (must keep aspect ratio + proportional DPI)
sh /data/local/tmp/Resolution-Master-Engine.sh apply <width> <height> <dpi>

# Confirm preview (required within 30s)
sh /data/local/tmp/Resolution-Master-Engine.sh confirm <token>

# Manual revert of current preview
sh /data/local/tmp/Resolution-Master-Engine.sh revert <token>

# Restore last original state
sh /data/local/tmp/Resolution-Master-Engine.sh restore

# Full reset to physical native resolution
sh /data/local/tmp/Resolution-Master-Engine.sh reset

# Status (JSON)
sh /data/local/tmp/Resolution-Master-Engine.sh status
```

---

## 🔄 7 · Transsion Sync / Sinkronisasi XOS

When `SYNC_TRANSSION_XOS=1` the engine also writes:

```sh
settings put system tran_resolution_size_0 <WxH>
settings put system tran_resolution_size_1 <WxH>
settings put system tran_resolution_default <WxH>
setprop debug.hwc.fbsize <WxH>
```

This keeps the Transsion display settings database and HWC framebuffer consistent with the WindowManager override.

---

## ⚠️ 8 · Risk & DWYOR / Risiko

| Action | Level | EN Risk | ID Risiko | Safe Default |
|--------|-------|---------|-----------|:------------:|
| PREVIEW mode | 🟢 LOW | Temporary change, auto-rollback | Perubahan sementara, auto-rollback | Recommended |
| INSTANT mode | 🟡 MEDIUM | No auto-rollback | Tidak ada auto-rollback | Only for automation |
| EXTREME 50% | 🟡 MEDIUM | Very soft image, touch may feel different | Gambar sangat lembut, sentuhan terasa berbeda | Tournament only |
| Custom apply | 🟠 HIGH | Invalid ratio can cause UI issues | Rasio invalid bisa merusak UI | Keep aspect ratio |
| Permanent lock without testing | 🔴 EXTREME | Rare soft-brick on broken OEM | Soft-brick jarang pada OEM rusak | Always use PREVIEW first |

> **DWYOR** = Do With Your Own Risk  
> Always test with PREVIEW mode first.

---

## 🔄 9 · Quick Reset / Perintah Reset

```bash
# Full native restore
sh /data/local/tmp/Resolution-Master-Engine.sh reset

# Or manual AOSP commands
wm size reset
wm density reset

# Transsion cleanup (if needed)
settings delete system tran_resolution_size_0
settings delete system tran_resolution_size_1
settings delete system tran_resolution_default
setprop debug.hwc.fbsize ""
```

---

## 📜 10 · Changelog / Riwayat Versi

### v1.0.0 — Public Release (B64 Master Architecture)

```
EN:
+ Complete rewrite as pure POSIX shell
+ 30-second Safety Watchdog with independent guard process
+ Specialized Golden/Performance/Extreme profiles for Note 50 Pro
+ Universal Dynamic Engine for all other Android devices
+ Proportional DPI via diagonal formula
+ Strict aspect-ratio + minimum 30% size validation
+ Transsion XOS/HiOS system database sync
+ Atomic state directory + lock
+ JSON status output
+ Companion to Milkyway Equation (Project Genesis)

ID:
+ Rewrite total sebagai shell POSIX murni
+ Safety Watchdog 30 detik dengan proses guard independen
+ Profil khusus Golden/Performance/Extreme untuk Note 50 Pro
+ Universal Dynamic Engine untuk semua perangkat Android lain
+ DPI proporsional via rumus diagonal
+ Validasi rasio aspek ketat + minimum 30% ukuran
+ Sinkronisasi database sistem Transsion XOS/HiOS
+ Atomic state directory + lock
+ Output status JSON
+ Pendamping resmi Milkyway Equation (Project Genesis)
```

---

<div align="center">

---

*🌌 Project Genesis — Resolution Master Engine*

*Base author: Aceng D Monk · Public Edition 1.0.0*

*Target: All Android 11–16 · Primary: Transsion Group (Infinix · Tecno · Itel)*

*Companion to: The Milky Way Equation*

---

*"Go Big or Go Home. Tanpa setengah-setengah."*

</div>
