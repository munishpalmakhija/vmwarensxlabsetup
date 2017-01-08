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



$dlrgateway = $config.edge.internalnicip
$esggateway = $config.edge.uplinkgateway


$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}


###############DLR Configuration ############################

$uridlrdetails="https://$NSXIP/api/4.0/edges/?edgeType=distributedRouter"
$dlrdetails = Invoke-RestMethod -Uri $uridlrdetails -Method Get -Headers $header -ContentType "application/xml"
$dlrid = $dlrdetails.pagedEdgeList.edgePage.edgeSummary.objectId

$uridlrdg = "https://$NSXIP/api/4.0/edges/$dlrid/routing/config/static"

$dlrdgbody = "<staticRouting>
    <defaultRoute>
<vnic>2</vnic>
<gatewayAddress>$dlrgateway</gatewayAddress>
<mtu>1500</mtu>
</defaultRoute>
</staticRouting>"

try {
	Write-Host -BackgroundColor:Black -ForegroundColor:Yellow "Status - Configuring Default Gateway for DLR"
	$result = Invoke-RestMethod -Uri $uridlrdg -Method Put -Headers $header -ContentType "application/xml" -Body $dlrdgbody -TimeoutSec 1200 -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - Default Gateway has been configured for DLR"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
	$responseBody
 }

###############Edge Configuration ############################

$uriedgedetails="https://$NSXIP/api/4.0/edges/?edgeType=gatewayServices"
$edgdetails = Invoke-RestMethod -Uri $uriedgedetails -Method Get -Headers $header -ContentType "application/xml"
$egid = $edgdetails.pagedEdgeList.edgePage.edgeSummary.objectId

$uridg = "https://$NSXIP/api/4.0/edges/$egid/routing/config/static"

$edgedgbody = "<staticRouting>
    <defaultRoute>
<vnic>0</vnic>
<gatewayAddress>$esggateway</gatewayAddress>
<mtu>1500</mtu>
</defaultRoute>
</staticRouting>"

try {
	Write-Host -BackgroundColor:Black -ForegroundColor:Yellow "Status - Configuring Default Gateway for Edge"
	$result = Invoke-RestMethod -Uri $uridg -Method Put -Headers $header -ContentType "application/xml" -Body $edgedgbody -TimeoutSec 1200 -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - Default Gateway has been configured for Edge"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
	$responseBody
 }


Disconnect-VIServer * -Confirm:$false



