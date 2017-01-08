##### JSON Details #####

$jsonpath = "C:\Scripts\infradetails.json"
$config = Get-Content -Raw -Path $jsonpath | ConvertFrom-Json

##### VC Details #####

$vCenterIP = $config.vsphere.vcenterip
$vcuser = $config.vsphere.vcuser
$vcpass = $config.vsphere.vcpass

##### NSX Details Config #####

$Username = $config.nsx.user
$NSXIP = $config.nsx.ip
$NSXPass = $config.nsx.pass

##### VC Connection #####

Connect-VIServer $vCenterIP -User $vcuser -Password $vcpass | Out-Null


$cluster = $config.vsphere.clustername
$dc = $config.vsphere.dcname
$moref = @{}
$moref.Add("datacenter",(Get-Datacenter $dc | Get-View).MoRef.Value)
$moref.Add("cluster",(Get-Cluster $cluster | Get-View).MoRef.Value)
$c = $moref.cluster

##### API Config #####

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$uri="https://$NSXIP/api/2.0/nwfabric/configure"
$body = "<nwFabricFeatureConfig> <resourceConfig> <resourceId>$c</resourceId> </resourceConfig> </nwFabricFeatureConfig>"

##### Execution #####

# Here we use a try catch to catch any exceptions which may occur from Invoke-Webrequest
 
try {
        $result = Invoke-RestMethod -Uri $uri -Method Post -Headers $header -ContentType "application/xml" -Body $body -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - Host Preparation Started. Please refer the vSphere Web Client for Installation Status"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
 }
 
$responseBody


Disconnect-VIServer * -Confirm:$false
