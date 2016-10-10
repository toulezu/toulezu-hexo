@echo off
set base_path=D:\git-workspace\toulezu
set public_path=%base_path%\public
set hexo_public=%base_path%\hexo\public
set theme_path=%base_path%\hexo\themes

@echo [INFO] ------------------------------------------------------------------------执行 hexo g 命令
D:
cd %base_path%\hexo
call hexo clean
call hexo g

@echo [INFO] ------------------------------------------------------------------------将 %hexo_public% 下的文件复制到 %public_path%
xcopy %hexo_public%\*.* %public_path% /e /y

@echo [INFO] ------------------------------------------------------------------------将 %theme_path%\next 下的配置文件复制到 %theme_path%
if exist %theme_path%\_config.yml del /f/q %theme_path%\_config.yml
if exist %theme_path%\_config.yml.next del /f/q %theme_path%\_config.yml.next

xcopy %theme_path%\next\_config.yml %theme_path% /y
ren %theme_path%\_config.yml _config.yml.next

@echo [INFO] ------------------------------------------------------------------------启动本地hexo服务
call hexo s

pause