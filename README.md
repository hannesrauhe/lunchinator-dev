lunchinator-dev
===============

A repository to manage all the stuff we need around the lunchinator.


To build lunchinator packages, sign, and upload to ftp
===========

Windows:
everything in one script: make_win.bat

you need pyinstaller, Inno Setup, gnupg and pip

run cmd as Administrator for everything related to pip

install pip:
https://raw.githubusercontent.com/pypa/pip/master/contrib/get-pip.py

install pswin32 for pyinstaller:
http://sourceforge.net/projects/pywin32/

install pyinstaller:
c:\Python2.7\python.exe -m pip install pyinstaller

install psutil for gnupg :
https://pypi.python.org/pypi/psutil#downloads

install gpg: (vanilla)
http://www.gpg4win.org/

install python-gnupg, uuid via pip
c:\Python2.7\python.exe -m pip install gnupg uuid

install innosetup

install lunchinator requirements for pyinstaller packages:
*pyqt4 
c:\Python2.7\python.exe -m pip install yapsy

automatic Upload to ftp (currently win only, active ftp connection necessary - firewall): 
hashnsigh.py generates commands.ftp if os.getenv("LUNCHINATOR_UPLOAD_FTP") returns the name of a file with the FTP details
(make win sets LUNCHINATOR_UPLOAD_FTP to <branch>.ftp)
commands.ftp creates the necessary directories on the server and uploads setup.exe
for this to work: store <branch>.ftp with one line: user:pass@server
