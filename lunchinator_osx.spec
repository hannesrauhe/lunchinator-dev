# -*- mode: python -*-

import os, sys
if os.getenv("LUNCHINATOR_GIT"):
    gitDir = os.getenv("LUNCHINATOR_GIT")
elif os.path.isdir("lunchinator"):
    print "Using fallback directory"
    gitDir = "lunchinator"
else:
    sys.stderr.write("Lunchinator source code directory not found.\n")
    sys.exit(1)

anaFiles = ["%s/start_lunchinator.py" % gitDir]
anaFiles.extend(aFile for aFile in os.listdir("%s/plugins" % gitDir) if os.path.isfile(aFile) and aFile.endswith(".py"))
for aFile in os.listdir("%s/plugins" % gitDir):
    aFile = os.path.join("%s/plugins" % gitDir, aFile)
    if aFile.endswith(".py"):
        anaFiles.append(aFile)
    if os.path.isdir(aFile):
        if os.path.exists(os.path.join(aFile, "__init__.py")):
            for aFile2 in os.listdir(aFile):
                if aFile2.endswith(".py"):
                    anaFiles.append(os.path.join(aFile, aFile2))

a = Analysis(anaFiles,
             pathex=['..'],
             hiddenimports=[],
             hookspath=None,
             runtime_hooks=None)
pyz = PYZ(a.pure)
exe = EXE(pyz,
          a.scripts,
          exclude_binaries=True,
          name='Lunchinator',
          debug=False,
          strip=None,
          upx=True,
          console=False , icon="%s/images/lunchinator.icns" % gitDir)
coll = COLLECT(exe,
               a.binaries,
               a.zipfiles,
               a.datas,
               strip=None,
               upx=True,
               name='Lunchinator')
app = BUNDLE(coll,
             name='Lunchinator.app',
             info_plist={
               'CFBundleIdentifier': "hannesrauhe.lunchinator",
               'NSPrincipalClass': 'NSApplication',
               'LSUIElement': 'True',
               'LSBackgroundOnly': 'False'
             },
             icon="%s/images/lunchinator.icns" % gitDir)
