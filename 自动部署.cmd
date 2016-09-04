@echo off
set hexo_path=D:\workspace\git-toulezu\hexo
set hexo_public=%hexo_path%\public
set theme_path=%hexo_path%\themes
set theme_next=%theme_path%\next
set public_path=D:\workspace\git-toulezu\public

@echo [INFO] ------------------------------------------------------------------------执行 hexo g 命令
D:
cd %hexo_path%
call hexo clean
call hexo g

@echo [INFO] ------------------------------------------------------------------------将 %hexo_public% 下的文件复制到 %public_path%
xcopy %hexo_public%\*.* %public_path% /e /y

@echo [INFO] ------------------------------------------------------------------------将 %theme_next% 下的配置文件复制到 %theme_path%
if exist %theme_path%\_config.yml del /f/q %theme_path%\_config.yml
if exist %theme_path%\_config.yml.next del /f/q %theme_path%\_config.yml.next

xcopy %theme_next%\_config.yml %theme_path% /y
ren %theme_path%\_config.yml _config.yml.next

@echo [INFO] ------------------------------------------------------------------------启动本地hexo服务
call hexo s

pause