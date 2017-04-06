setlocal
cd C:\vdirs\doi\AssignDOIs\builder
echo [%date% - %time%] Log start >> C:\vdirs\doi\AssignDOIs\logs\batchlog.txt
echo %cd% >> C:\vdirs\doi\AssignDOIs\logs\batchlog.txt
for /r %%i in (.\R\*) do echo %%i >> C:\vdirs\doi\AssignDOIs\logs\batchlog.txt
"C:\Program Files\R\R-3.3.2\bin\x64\Rcmd.exe" BATCH C:\vdirs\doi\AssignDOIs\builder\R\processing_code.R C:\vdirs\doi\AssignDOIs\logs\output.txt
endlocal