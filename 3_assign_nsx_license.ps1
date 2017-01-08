##### JSON Details #####

$jsonpath = "C:\Scripts\infradetails.json"
$config = Get-Content -Raw -Path $jsonpath | ConvertFrom-Json

##### VC Details #####

$vCenterIP = $config.vsphere.vcenterip
$vcuser = $config.vsphere.vcuser
$vcpass = $config.vsphere.vcpass

##### VC Connection #####

Connect-VIServer $vCenterIP -User $vcuser -Password $vcpass | Out-Null

$licensekey = $config.nsx.licensekey

$ServiceInstance = Get-View ServiceInstance
$LicenseManager = Get-View $ServiceInstance.Content.licenseManager
$LicenseAssignmentManager = Get-View $LicenseManager.licenseAssignmentManager

try {
	$result = $LicenseAssignmentManager.UpdateAssignedLicense("nsx-netsec",$licensekey,$NULL)
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - NSX License has been applied successfully . Please refer the vSphere Web Client !!!"       
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
	$responseBody
 }



Disconnect-VIServer * -Confirm:$false
