import os
anaFiles = ["start_lunchinator.py"]
anaFiles.extend(aFile for aFile in os.listdir("plugins") if os.path.isfile(aFile) and aFile.endswith(".py"))
for aFile in os.listdir("plugins"):
    aFile = os.path.join("plugins", aFile)
    if aFile.endswith(".py"):
        anaFiles.append(aFile)
    if os.path.isdir(aFile):
        if os.path.exists(os.path.join(aFile, "__init__.py")):
             anaFiles.append(os.path.join(aFile, "__init__.py"))

# -*- mode: python -*-
a = Analysis(anaFiles,
             pathex=['.'],
             hiddenimports=['netrc','markdown.extensions.extra',
			'markdown.extensions.smart_strong',
			'markdown.extensions.fenced_code',
			'markdown.extensions.footnotes',
			'markdown.extensions.attr_list',
			'markdown.extensions.def_list',
			'markdown.extensions.tables',
			'markdown.extensions.abbr'],
             hookspath=None,
             runtime_hooks=None)

#workaround for http://www.pyinstaller.org/ticket/783#comment:5
for d in a.datas:
    if 'pyconfig' in d[0]: 
        a.datas.remove(d)
        break
#workaround not necessary with Pyinstaller > 2.2

pyz = PYZ(a.pure)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          name='lunchinator.exe',
          debug=False,
          strip=None,
          upx=False,
	  console = False,
	  icon='images\\lunchinator.ico')
		  
