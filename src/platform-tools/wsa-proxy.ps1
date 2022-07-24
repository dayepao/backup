$WinNetIP=$(Get-NetIPAddress -InterfaceAlias 'vEthernet (WSL)' -AddressFamily IPV4)
.\adb connect 127.0.0.1:58526
.\adb shell settings put global http_proxy "$($WinNetIP.IPAddress):10811"  #7890换成你自己的代理端口