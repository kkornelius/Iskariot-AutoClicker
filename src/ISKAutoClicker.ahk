#NoEnv
#SingleInstance Force
SetBatchLines, -1
CoordMode, Mouse, Screen 
SendMode Input
SetWorkingDir %A_ScriptDir%

; ================= WARNA TEMA (DARK MODE) =================
Global ColorBG := "1E1E1E"    
Global ColorTxt := "00FF00"   
Global ColorBtn := "FFFFFF"   

; ================= VARIABEL GLOBAL =================
; --- Variabel Simple Clicker ---
global ACRunning := false
global ACMode := "click"
global ACHotkey := "F6" ; Default Hotkey

; --- Variabel Macro Recorder ---
global Recording := false
global Playing := false
global MacroLog := []
global StartTime := 0
global PlayLoop := false
global LoopCounter := 0 ; Variabel Penghitung Loop Baru

; --- Variabel Settings ---
global SfxVol := 50        
global TransValue := 255   

; --- Variabel Pelacak Mouse ---
global oldX := -1
global oldY := -1
global LastLBtn := "U"
global LastRBtn := "U"
global ih 

; ================= GUI BUILD =================
Gui, +AlwaysOnTop +MinimizeBox
Gui, Color, %ColorBG%            
Gui, Font, s10 c%ColorTxt%, Segoe UI 

; Membuat Tabulasi
Gui, Add, Tab3,, Simple Clicker|Macro Recorder|Settings

; ================= TAB 1: SIMPLE CLICKER =================
Gui, Tab, 1
Gui, Add, GroupBox, x15 y40 w310 h130 c%ColorTxt%, Pengaturan Klik Simpel
Gui, Add, Text, xp+15 yp+25, Interval (ms):
Gui, Add, Edit, vACInterval w100 cBlack, 100 

Gui, Add, Radio, vACModeClick Checked gSetACMode x30 y+15 cWhite, Klik Kiri Repetitif
Gui, Add, Radio, vACModeHold gSetACMode x30 y+10 cWhite, Klik Kiri Tahan

Gui, Add, GroupBox, x15 y180 w310 h80 c%ColorTxt%, Hotkey Simpel
Gui, Add, Text, xp+15 yp+25, Tombol Start/Stop:

; Kotak Hotkey Input Manual (Anti-None)
Gui, Add, Hotkey, vACHotkeyInput w80 x+10 yp-3, %ACHotkey%
Gui, Add, Button, gApplyACHotkey x+10 yp w80 h25, Update

; --- STATUS CLICKER ---
Gui, Font, Bold s12
Gui, Add, Text, vACStatusText x10 y280 w320 Center cRed, Status: STOPPED
Gui, Font, s10 Norm c%ColorTxt%

; ================= TAB 2: MACRO RECORDER =================
Gui, Tab, 2
Gui, Add, Text, x20 y40 w300 Center vRecStatusTxt cYellow, SIAP (Tekan F1 untuk Rekam)

Gui, Add, Button, gToggleRecord x20 y70 w140 h40 vBtnRec, F1: REKAM
Gui, Add, Button, gTogglePlay x170 y70 w140 h40 vBtnPlay, F2: PLAY

Gui, Add, Button, gSaveMacro x20 y120 w140 h30, Simpan (Save)
Gui, Add, Button, gLoadMacro x170 y120 w140 h30, Muat (Load)

Gui, Add, Button, gClearMacro x20 y160 w290 h30, Hapus Memori / Reset

; --- UPDATE: LOOP COUNTER ---
Gui, Add, Checkbox, vPlayLoop x20 y200 cWhite, Loop Playback
; Teks penghitung loop di sebelah checkbox
Gui, Font, Bold cLime
Gui, Add, Text, x150 y200 w150 vLoopCountTxt, Loops: 0
Gui, Font, Norm c%ColorTxt%

Gui, Add, Text, x20 y230 w300 cGray, F3: Stop Playback / Emergency Stop
Gui, Add, Text, x20 y250 w300 cGray, Info: Simpan rekaman agar tidak hilang!

; ================= TAB 3: SETTINGS =================
Gui, Tab, 3

Gui, Add, GroupBox, x15 y40 w310 h100 c%ColorTxt%, Tampilan (Ghost Mode)
Gui, Add, Text, xp+15 yp+25, Transparansi Background:
Gui, Add, Slider, vTransValue gSetTrans x25 y+5 w290 Range50-255 ToolTip, 255
Gui, Font, s8 cGray
Gui, Add, Text, x25 y+2, Geser ke kiri agar tembus pandang
Gui, Font, s10 c%ColorTxt% 

Gui, Add, GroupBox, x15 y150 w310 h100 c%ColorTxt%, Suara (SFX)
Gui, Add, Text, xp+15 yp+25, Volume Beep:
Gui, Add, Slider, vSfxVol x25 y+5 w290 Range0-100 ToolTip, 50
Gui, Font, s8 cGray
Gui, Add, Text, x25 y+2, 0 = Mute | 100 = Nyaring
Gui, Font, s10 c%ColorTxt% 

Gui, Add, GroupBox, x15 y260 w310 h60 c%ColorTxt%, Info
Gui, Add, Text, xp+15 yp+20, Status: MsgBox Fixed.

; ================= FOOTER =================
Gui, Tab 
Gui, Show, w350 h400, ISKAutoClicker

; Inisialisasi Hotkey Default
Gosub, InitHotkey
return

; ================= LOGIKA SETTINGS =================

SetTrans:
    Gui, Submit, NoHide
    WinSet, Transparent, %TransValue%, ISKAutoClicker
return

PlayBeep(Type) {
    Gui, Submit, NoHide
    if (SfxVol <= 0)
        return
    if (Type = "Start") {
        SoundBeep, 750, % (SfxVol * 2) 
    } else {
        SoundBeep, 500, % (SfxVol * 2)
    }
}

; ================= LOGIKA SIMPLE CLICKER =================

SetACMode:
    Gui, Submit, NoHide
    if (ACModeClick = 1)
        ACMode := "click"
    else
        ACMode := "hold"
return

ApplyACHotkey:
    Gui, Submit, NoHide
    Gui, +OwnDialogs ; <--- FIX: Agar MsgBox muncul di depan GUI
    
    if (ACHotkeyInput = "") {
        MsgBox, 48, Gagal, Tombol tidak boleh kosong (None)!`nSistem akan mengembalikan ke tombol sebelumnya.
        GuiControl,, ACHotkeyInput, %ACHotkey% 
        return
    }
    
    if (ACHotkeyInput = ACHotkey)
        return 

    try {
        if (ACHotkey != "") 
            Hotkey, %ACHotkey%, ToggleSimpleClick, Off 
            
        Hotkey, %ACHotkeyInput%, ToggleSimpleClick, On  
        ACHotkey := ACHotkeyInput
        MsgBox, 64, Sukses, Hotkey berhasil diubah!
        
    } catch {
        MsgBox, 16, Error, Tombol ini dilindungi sistem.`nSilakan pilih tombol lain.
        GuiControl,, ACHotkeyInput, %ACHotkey%
        try {
            Hotkey, %ACHotkey%, ToggleSimpleClick, On
        }
    }
return

InitHotkey:
    try {
        Hotkey, %ACHotkey%, ToggleSimpleClick, On
    }
return

ToggleSimpleClick:
    if (Recording || Playing) {
        Gui, +OwnDialogs ; <--- FIX
        MsgBox, 48, Konflik, Matikan Macro Recorder dulu sebelum pakai Simple Clicker!
        return
    }

    if (!ACRunning) {
        ACRunning := true
        GuiControl,, ACStatusText, Status: RUNNING...
        Gui, Font, cLime
        GuiControl, Font, ACStatusText
        PlayBeep("Start")

        if (ACMode = "hold") {
            Click down
        } else {
            SetTimer, DoSimpleClick, %ACInterval%
        }
    } else {
        ACRunning := false
        GuiControl,, ACStatusText, Status: STOPPED
        Gui, Font, cRed
        GuiControl, Font, ACStatusText
        PlayBeep("Stop")

        SetTimer, DoSimpleClick, Off
        Click up
    }
return

DoSimpleClick:
    if (!ACRunning)
        return
    Click
return

; ================= LOGIKA MACRO RECORDER =================

F1::GoSub, ToggleRecord
F2::GoSub, TogglePlay
F3::GoSub, StopAll

SaveMacro:
    if (Recording || Playing)
        return
    
    Gui, +OwnDialogs ; <--- FIX: Agar FileSelectFile dan MsgBox muncul di depan
    
    if (MacroLog.MaxIndex() = "" || MacroLog.MaxIndex() = 0) {
        MsgBox, 48, Kosong, Tidak ada rekaman untuk disimpan!
        return
    }

    FileSelectFile, SavePath, S16, MacroRekaman.txt, Simpan Rekaman, Text Documents (*.txt)
    if (SavePath = "")
        return

    if (SubStr(SavePath, -3) != ".txt")
        SavePath .= ".txt"

    FileDelete, %SavePath% 
    
    For i, Event in MacroLog {
        Line := ""
        if (Event.Type = "Move")
            Line := "Move," . Event.X . "," . Event.Y . "," . Event.Time
        else if (Event.Type = "LButton")
            Line := "LButton," . Event.State . "," . Event.Time
        else if (Event.Type = "RButton")
            Line := "RButton," . Event.State . "," . Event.Time
        else if (Event.Type = "Key")
            Line := "Key," . Event.Key . "," . Event.State . "," . Event.Time
        else if (Event.Type = "Sleep")
            Line := "Sleep," . Event.Time
        
        FileAppend, %Line%`n, %SavePath%
    }
    
    MsgBox, 64, Sukses, Rekaman berhasil disimpan!
return

LoadMacro:
    if (Recording || Playing)
        return

    Gui, +OwnDialogs ; <--- FIX: Agar FileSelectFile muncul di depan
    
    FileSelectFile, LoadPath, 3, , Buka Rekaman, Text Documents (*.txt)
    if (LoadPath = "")
        return

    MacroLog := []
    
    Loop, Read, %LoadPath%
    {
        if (A_LoopReadLine = "")
            continue
            
        Parts := StrSplit(A_LoopReadLine, ",")
        Type := Parts[1]
        
        if (Type = "Move")
            MacroLog.Push({Type: "Move", X: Parts[2], Y: Parts[3], Time: Parts[4]})
        else if (Type = "LButton")
            MacroLog.Push({Type: "LButton", State: Parts[2], Time: Parts[3]})
        else if (Type = "RButton")
            MacroLog.Push({Type: "RButton", State: Parts[2], Time: Parts[3]})
        else if (Type = "Key")
            MacroLog.Push({Type: "Key", Key: Parts[2], State: Parts[3], Time: Parts[4]})
        else if (Type = "Sleep")
            MacroLog.Push({Type: "Sleep", Time: Parts[2]})
    }
    
    Count := MacroLog.MaxIndex()
    if (Count = "")
        Count := 0
        
    GuiControl,, RecStatusTxt, FILE DIMUAT (%Count% Event)
    GuiControl, Enable, BtnPlay
    MsgBox, 64, Sukses, Berhasil memuat %Count% event!
return

ClearMacro:
    if (Recording || Playing) {
        Gui, +OwnDialogs ; <--- FIX
        MsgBox, 48, Gagal, Stop dulu rekaman atau playback-nya!
        return
    }
    
    MacroLog := "" 
    MacroLog := [] 
    
    GuiControl,, RecStatusTxt, MEMORI BERSIH (Siap Rekam)
    GuiControl, Disable, BtnPlay 
    GuiControl, Text, BtnRec, F1: REKAM 
    SetTimer, RecordMouse, Off
    
    Gui, +OwnDialogs ; <--- FIX
    MsgBox, 64, Info, Memori rekaman SUDAH BERSIH TOTAL.
return

ToggleRecord:
    if (Playing || ACRunning)
        return

    if (!Recording) {
        Recording := true
        MacroLog := [] 
        StartTime := A_TickCount
        
        MouseGetPos, mX, mY
        oldX := mX
        oldY := mY
        LastLBtn := GetKeyState("LButton", "P") ? "D" : "U"
        LastRBtn := GetKeyState("RButton", "P") ? "D" : "U"
        
        GuiControl,, RecStatusTxt, SEDANG MEREKAM... (F1 Stop)
        GuiControl, Text, BtnRec, F1: STOP
        GuiControl, Disable, BtnPlay
        PlayBeep("Start")
        
        ih := InputHook("V")
        ih.KeyOpt("{All}", "N")
        ih.OnKeyDown := Func("LogKeyDown")
        ih.OnKeyUp := Func("LogKeyUp")
        ih.Start()
        
        SetTimer, RecordMouse, 15
        
    } else {
        Recording := false
        ih.Stop()
        SetTimer, RecordMouse, Off
        
        GuiControl,, RecStatusTxt, REKAMAN TERSIMPAN!
        GuiControl, Text, BtnRec, F1: REKAM ULANG
        GuiControl, Enable, BtnPlay
        PlayBeep("Stop")
        
        count := MacroLog.MaxIndex()
        if (count = "")
            count := 0
            
        LastTime := (count > 0) ? MacroLog[count].Time : 0
        MacroLog.Push({Type: "Sleep", Time: LastTime + 500})
        
        Gui, +OwnDialogs ; <--- FIX
        MsgBox, 64, Sukses, Rekaman Selesai!`nTotal Event: %count%
    }
return

RecordMouse:
    if (!Recording)
        return

    TimeNow := A_TickCount - StartTime
    MouseGetPos, mX, mY
    
    if (mX != oldX || mY != oldY) {
        MacroLog.Push({Type: "Move", X: mX, Y: mY, Time: TimeNow})
        oldX := mX
        oldY := mY
    }
    
    currL := GetKeyState("LButton", "P") ? "D" : "U"
    if (currL != LastLBtn) {
        MacroLog.Push({Type: "LButton", State: currL, Time: TimeNow})
        LastLBtn := currL
    }
    
    currR := GetKeyState("RButton", "P") ? "D" : "U"
    if (currR != LastRBtn) {
        MacroLog.Push({Type: "RButton", State: currR, Time: TimeNow})
        LastRBtn := currR
    }
return

LogKeyDown(ih, VK, SC) {
    if (!Recording)
        return
    TimeNow := A_TickCount - StartTime
    KeyName := GetKeyName(Format("vk{:x}sc{:x}", VK, SC))
    MacroLog.Push({Type: "Key", Key: KeyName, State: "Down", Time: TimeNow})
}

LogKeyUp(ih, VK, SC) {
    if (!Recording)
        return
    TimeNow := A_TickCount - StartTime
    KeyName := GetKeyName(Format("vk{:x}sc{:x}", VK, SC))
    MacroLog.Push({Type: "Key", Key: KeyName, State: "Up", Time: TimeNow})
}

TogglePlay:
    if (Recording || ACRunning)
        return
    
    Gui, Submit, NoHide
    
    Gui, +OwnDialogs ; <--- FIX (Jaga-jaga jika ada msgbox di sini)
    if (MacroLog.MaxIndex() = "" || MacroLog.MaxIndex() = 0) {
        MsgBox, 48, Kosong, Belum ada rekaman untuk dimainkan!
        return
    }

    Playing := true
    GuiControl,, RecStatusTxt, PLAYING... (F3 Stop)
    GuiControl, Disable, BtnRec
    GuiControl, Disable, BtnPlay
    GuiControl, Disable, gLoadMacro
    PlayBeep("Start")
    
    ; RESET LOOP COUNTER
    LoopCounter := 0
    GuiControl,, LoopCountTxt, Loops: 0
    
    Loop {
        if (!Playing)
            break
            
        StartTimePlay := A_TickCount
        
        For i, Event in MacroLog {
            if (!Playing)
                break
                
            TargetTime := Event.Time
            CurrentDelay := (A_TickCount - StartTimePlay)
            WaitTime := TargetTime - CurrentDelay
            
            if (WaitTime > 0)
                DllCall("Sleep", "UInt", WaitTime)
            
            if (Event.Type = "Move") {
                MouseMove, Event.X, Event.Y, 0
            } 
            else if (Event.Type = "LButton") {
                if (Event.State = "D")
                    Click, Down
                else
                    Click, Up
            }
            else if (Event.Type = "RButton") {
                if (Event.State = "D")
                    Click, Right, Down
                else
                    Click, Right, Up
            }
            else if (Event.Type = "Key") {
                k := Event.Key
                if (Event.State = "Down")
                    SendInput, {Blind}{%k% Down}
                else
                    SendInput, {Blind}{%k% Up}
            }
        }
        
        ; LOGIKA UPDATE COUNTER
        LoopCounter++
        GuiControl,, LoopCountTxt, Loops: %LoopCounter%
        
        if (!PlayLoop)
            break
            
        Sleep, 200
    }
    
    Gosub, StopAll
return

StopAll:
    Playing := false
    GuiControl,, RecStatusTxt, SIAP (Tekan F1 untuk Rekam)
    GuiControl, Enable, BtnRec
    GuiControl, Enable, BtnPlay
    GuiControl, Enable, gLoadMacro
    PlayBeep("Stop")
    SendInput, {LButton Up}{RButton Up}
return

GuiClose:
ExitApp