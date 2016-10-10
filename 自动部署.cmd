@echo off
set base_path=D:\git-workspace\toulezu
set public_path=%base_path%\public
set hexo_public=%base_path%\hexo\public
set theme_path=%base_path%\hexo\themes

@echo [INFO] ------------------------------------------------------------------------ִ�� hexo g ����
D:
cd %base_path%\hexo
call hexo clean
call hexo g

@echo [INFO] ------------------------------------------------------------------------�� %hexo_public% �µ��ļ����Ƶ� %public_path%
xcopy %hexo_public%\*.* %public_path% /e /y

@echo [INFO] ------------------------------------------------------------------------�� %theme_path%\next �µ������ļ����Ƶ� %theme_path%
if exist %theme_path%\_config.yml del /f/q %theme_path%\_config.yml
if exist %theme_path%\_config.yml.next del /f/q %theme_path%\_config.yml.next

xcopy %theme_path%\next\_config.yml %theme_path% /y
ren %theme_path%\_config.yml _config.yml.next

@echo [INFO] ------------------------------------------------------------------------��������hexo����
call hexo s

pause