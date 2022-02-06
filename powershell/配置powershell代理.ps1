# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1


if (!(Test-Path -Path $PROFILE.AllUsersAllHosts)) {
    New-Item -ItemType File -Path $PROFILE.AllUsersAllHosts -Force
}
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.1#how-to-create-a-profile

$content = @"
function set_proxy_variable {
    Set-Item Env:http_proxy "http://127.0.0.1:10809"  # http�����ַ
    Write-Output "����http����"
    Set-Item Env:https_proxy "http://127.0.0.1:10809" # https�����ַ
    Write-Output "����https����"
}

function unset_proxy_variable {
    try {
        Remove-Item Env:http_proxy -ErrorAction Stop
        Write-Output "ֹͣhttp����"
    }
    catch {
        Write-Output "δ����http����"
    }
    try {
        Remove-Item Env:https_proxy -ErrorAction Stop
        Write-Output "ֹͣhttps����"
    }
    catch {
        Write-Output "δ����https����"
    }
}

New-Alias -Name setp -Value set_proxy_variable
New-Alias -Name unsetp -Value unset_proxy_variable
"@

add-content $PROFILE.AllUsersAllHosts $content
Write-Output "������ɣ������ն˺���Ч`n����setp��������`n����unsetpֹͣ����"