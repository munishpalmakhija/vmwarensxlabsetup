##### JSON Details #####

$jsonpath = "C:\Scripts\infradetails.json"
$config = Get-Content -Raw -Path $jsonpath | ConvertFrom-Json

##### VC Details #####

$vCenterIP = $config.mgmtvsphere.vcenterip
$vcuser = $config.mgmtvsphere.vcuser
$vcpass = $config.mgmtvsphere.vcpass

##### VC Connection #####

Connect-VIServer $vCenterIP -User $vcuser -Password $vcpass | Out-Null

##### NSX Details Config #####

$Username = $config.nsx.user
$NSXIP = $config.nsx.ip
$NSXPass = $config.nsx.pass
$NSXPath = $config.nsx.ovapath
$VMName = $config.nsx.vmname
$vmhost = $config.mgmtvsphere.esxihost
$ds = $config.mgmtvsphere.mgrdatastore
$portgroup = $config.mgmtvsphere.mgrportgroup
$gateway = $config.nsx.gateway
$netmask = $config.nsx.subnetmask
$sshEnabled = $config.nsx.sshEnabled
$hostname = $config.nsx.hostname
$ntp = $config.nsx.ntp
$dns0 = $config.nsx.dns_0

$ovfconfig = @{
"vsm_cli_en_passwd_0" = $NSXPass
"NetworkMapping.VSMgmt" = $portgroup
"vsm_gateway_0" = $gateway
"vsm_cli_passwd_0" = $NSXPass
"vsm_isSSHEnabled" = $sshEnabled
"vsm_netmask_0" = $netmask
"vsm_hostname" = $hostname
"vsm_ntp_0" = $ntp
"vsm_dns1_0" = $dns0
"vsm_ip_0" = $NSXIP
}
Import-VApp -Source $NSXPath -OVFConfiguration $ovfconfig -Name $VMName -VMhost $vmhost -Datastore $ds -DiskStorageFormat "Thin" | Out-Null
Start-VM -VM $VMName -Confirm:$false | Out-Null
$VM_View = get-vm $vmname | get-view
$toolsstatus = $VM_View.Summary.Guest.ToolsRunningStatus
write-host "Waiting for $vmname to boot up" -foregroundcolor 'Yellow'
do {
Sleep -seconds 20
$VM_View = get-vm $vmname | get-view
$toolsstatus = $VM_View.Summary.Guest.ToolsRunningStatus
} Until ($toolsstatus -eq "guestToolsRunning")

Write-Host "$vmname has booted up successfully, Proceeding" -foregroundcolor 'Green'
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
 $uri = "https://$NSXIP/api/2.0/vdn/controller"
do {
	Start-Sleep -Seconds 20
	$result = try { Invoke-WebRequest -Uri $uri -Headers $header -ContentType "application/xml"} catch { $_.Exception.Response}
} Until ($result.statusCode -eq "200")

Write-Host "Connected to $NSXIP successfully." -foregroundcolor 'Green'

Disconnect-VIServer * -Confirm:$false