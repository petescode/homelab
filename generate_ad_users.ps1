Clear-Host
Import-Module ActiveDirectory

$password = Read-Host "Enter password" -AsSecureString

# want this to be OS agnostic; do input validation
$file = Read-Host "Enter path to names text file"

# home lab example
$ou = "OU=Regular Users,DC=laptopdomain,DC=local"

Get-Content $file | ForEach-Object{
    
    $fname = $_.split()[0]
    $lname = $_.split()[1]
    $samname = $_.ToLower() -replace " ","."

    New-ADUser -Path $ou -Name $_ -GivenName $fname -Surname $lname -SamAccountName $samname -AccountPassword $password -Enabled:$TRUE -ChangePasswordAtLogon:$TRUE -WhatIf
}