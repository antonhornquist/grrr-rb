@ECHO OFF
SET SCEXT_RB_ROOT=C:\path\to\scext-rb
ruby "-I%SCEXT_RB_ROOT%\lib" -Ilib test\tc_grrr.rb
ruby "-I%SCEXT_RB_ROOT%\lib" -Ilib test\tc_unstable.rb
ruby "-I%SCEXT_RB_ROOT%\lib" -Ilib test\tc_grrr_ruby.rb
REM below wont work...
REM rake "-I%SCEXT_RB_ROOT%\lib" -Ilib
