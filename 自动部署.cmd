@echo off
set hexo_path=D:\git-toulezu\toulezu-hexo
set hexo_public=D:\git-toulezu\toulezu-hexo\public
set public_path=D:\git-toulezu\toulezu-public

D:
cd %hexo_path%
call hexo g

xcopy %hexo_public%\*.* %public_path% /e /y

pause