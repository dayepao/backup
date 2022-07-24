$WinNetIP=$(Get-NetIPAddress -InterfaceAlias 'vEthernet (WSL)' -AddressFamily IPV4)
$current_path=$(Split-Path -Path $script:MyInvocation.MyCommand.Path)
$parent_path=$(Split-Path -Path $current_path -Parent)
$adb_path=Join-Path (Join-Path $parent_path "src") -ChildPath "platform-tools"
cd $adb_path
.\adb.exe connect 127.0.0.1:58526
.\adb.exe shell settings put global http_proxy "$($WinNetIP.IPAddress):10811"  #10811换成你自己的代理端口
cd $current_path