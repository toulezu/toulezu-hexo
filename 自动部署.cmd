@echo off
set hexo_path=D:\git-toulezu\toulezu-hexo
set hexo_public=%hexo_path%\public
set theme_path=%hexo_path%\themes
set theme_next=%theme_path%\next
set public_path=D:\git-toulezu\toulezu-public

@echo [INFO] ------------------------------------------------------------------------ִ�� hexo g ����
D:
cd %hexo_path%
call hexo clean
call hexo g

@echo [INFO] ------------------------------------------------------------------------�� %hexo_public% �µ��ļ����Ƶ� %public_path%
xcopy %hexo_public%\*.* %public_path% /e /y

@echo [INFO] ------------------------------------------------------------------------�� %theme_next% �µ������ļ����Ƶ� %theme_path%
xcopy %theme_next%\_config.yml %theme_path% /y
ren %theme_path%\_config.yml _config.yml.next.bak

@echo [INFO] ------------------------------------------------------------------------��������hexo����
call hexo s

pause