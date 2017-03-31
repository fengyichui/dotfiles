::
:: @file associate.bat
:: @brief Auto associate file with application and icon
:: @date 2016/11/30
:: @author liqiang
::

@echo off

:: APP and ICON
set app="C:\Program Files (x86)\Vim\vim80\gvim.exe" "%%1"
::set icon="%%SystemRoot%%\system32\imageres.dll,97"
set icon="%~dp0vim.ico,0"

:: print info
echo ---------------------------------------------
echo app: %app%
echo icon: %icon%
echo ---------------------------------------------

:: Extension
set extensions=(c,cc,cpp,h,hpp, asm,s, java, bin,hex, map,dis,sct,symdefs, mk,mak, ini, log, md, vim, xml, diff,patch, sh, gdb)
:: Do Extension
for %%e in %extensions% do (
    ftype vim.%%e=%app%
    assoc .%%e=vim.%%e
    reg add hkcr\vim.%%e\DefaultIcon /ve /d %icon% /f
    echo ---------------------------------------------
)

:: No extension
ftype vim.noextension=%app%
assoc .=vim.noextension
reg add hkcr\vim.noextension\DefaultIcon /ve /d %icon% /f
echo ---------------------------------------------

:: txt file: special for shellnew
ftype txtfile=%app%
assoc .txt=txtfile
echo ---------------------------------------------

:: Pause
pause
