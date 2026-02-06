# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['C:\\Users\\SUSHANTH\\OneDrive\\Desktop\\CN_2TESTING\\Sapora\\Sapora\\client\\main_ui.py'],
    pathex=[],
    binaries=[],
    datas=[('C:\\Users\\SUSHANTH\\OneDrive\\Desktop\\CN_2TESTING\\Sapora\\Sapora\\client\\style.qss', '.')],
    hiddenimports=['PyQt6.sip'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['PyQt5', 'PySide6', 'PySide2'],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='SaporaClient',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
