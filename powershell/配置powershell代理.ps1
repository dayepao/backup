# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1


if (!(Test-Path -Path $PROFILE.AllUsersAllHosts)) {
    New-Item -ItemType File -Path $PROFILE.AllUsersAllHosts -Force
}
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.1#how-to-create-a-profile

$content = @"
function set_proxy_variable {
    Set-Item Env:http_proxy "http://127.0.0.1:10809"  # http代理地址
    Write-Output "启动http代理"
    Set-Item Env:https_proxy "http://127.0.0.1:10809" # https代理地址
    Write-Output "启动https代理"
}

function unset_proxy_variable {
    try {
        Remove-Item Env:http_proxy -ErrorAction Stop
        Write-Output "停止http代理"
    }
    catch {
        Write-Output "未开启http代理"
    }
    try {
        Remove-Item Env:https_proxy -ErrorAction Stop
        Write-Output "停止https代理"
    }
    catch {
        Write-Output "未开启https代理"
    }
}

New-Alias -Name setp -Value set_proxy_variable
New-Alias -Name unsetp -Value unset_proxy_variable
"@

add-content $PROFILE.AllUsersAllHosts $content
Write-Output "配置完成，重启终端后生效`n输入setp启动代理`n输入unsetp停止代理"