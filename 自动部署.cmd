@echo off
set hexo_path=D:\git-toulezu\toulezu-hexo
set hexo_public=D:\git-toulezu\toulezu-hexo\public
set public_path=D:\git-toulezu\toulezu-public

@echo [INFO] ------------------------------------------------------------------------执行 hexo g 命令
D:
cd %hexo_path%
call hexo clean
call hexo g

@echo [INFO] ------------------------------------------------------------------------将 %hexo_public% 下的文件复制到 %public_path%
xcopy %hexo_public%\*.* %public_path% /e /y

pause