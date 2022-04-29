#!/bin/pwsh

$Env:GOVC_URL = $Env:VCENTER_URI
$Env:GOVC_INSECURE = 1

try {
    Send-SlackMessage -Uri $Env:SLACK_WEBHOOK_URI -Text "Cleaning: $($Env:VCENTER_URI)"

    Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -Confirm:$false | Out-Null
    Connect-VIServer -Server $Env:VCENTER_URI -Credential (Import-Clixml $Env:VCENTER_SECRET_PATH) | Out-Null

    $resourcePools = Get-ResourcePool | Where-Object { $_.Name -match '^ci*|^qeci*' }

    foreach ($rp in $resourcePools) {
        [array]$resourcePoolVirtualMachines = $rp | Get-VM
        if ($resourcePoolVirtualMachines.Length -eq 0) {
            Write-Host "Remove RP: $($rp.Name)"
            Remove-ResourcePool -ResourcePool $rp -Confirm:$false -ErrorAction Continue
        }
    }
}
catch {
    Get-Error
    exit 1
}
finally {
    Disconnect-VIServer -Server * -Force:$true -Confirm:$false
}

exit 0
