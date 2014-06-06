@echo OFF
setlocal ENABLEDELAYEDEXPANSION
git clone https://github.com/hannesrauhe/lunchinator

set LUNCHINATOR_GIT=lunchinator
set CHANGELOG_PY=changelog.py

FOR %%B IN (master nightly) DO (
    if exist last_hash_makewin_%%B (
        set /p LAST_HASH=<last_hash_makewin_%%B
    ) else (
        REM Build will run through but changelog will be empty
        set LAST_HASH=HEAD
    )
    
    cd lunchinator
    git checkout %%B
	git pull
    git rev-parse HEAD>this_hash_makewin_%%B
    set /p THIS_HASH=<this_hash_makewin_%%B
    del this_hash_makewin_%%B
    
    if "!THIS_HASH!"=="!LAST_HASH!" (
        echo No new version in git for %%B
        cd ..
    ) else (
        echo !LAST_HASH! - !THIS_HASH!
        for /f "tokens=*" %%a in ('git describe --tags --abbrev^=0') do set tagname=%varText%%%a
        for /f "tokens=*" %%a in ('git rev-list HEAD --count') do set commitcount=%varText%%%a
        set VERSION=!tagname!.!commitcount!
        echo !VERSION!> version
        
        C:\\Python27\\scripts\\pyinstaller.exe -y -F -w ../lunchinator.spec
        RMDIR /S /Q build
        
        cd ..
        
        set LUNCHINATOR_BRANCH=%%B
        "C:\\Program Files (x86)\\Inno Setup 5\\Compil32.exe" /cc build_installer.iss
        RMDIR /S /Q lunchinator\dist
        
        set /p LUNCHINATOR_UPLOAD_FTP=<%%B.ftp
        "C:\\Python27\\python.exe" hashNsign.py win/setup_lunchinator.exe
        ftp -s:commands.ftp
        echo !THIS_HASH!>last_hash_makewin_%%B
    )
    set LAST_HASH=
    set THIS_HASH=
    set LUNCHINATOR_UPLOAD_FTP=
    set LUNCHINATOR_BRANCH=
)
