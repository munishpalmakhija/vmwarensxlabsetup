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

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}


###############DLR Details ############################

$dlrrouterid = $config.dlr.uplinkip
$dlrforwardingaddress = $config.dlr.uplinkip
$dlrprotocoladdress = $config.ospf.protocoladdress
$ospfareaid = $config.ospf.areaid


$uridlrdetails="https://$NSXIP/api/4.0/edges/?edgeType=distributedRouter"
$dlrdetails = Invoke-RestMethod -Uri $uridlrdetails -Method Get -Headers $header -ContentType "application/xml"
$dlrid = $dlrdetails.pagedEdgeList.edgePage.edgeSummary.objectId

###############DLR Router ID Configuration ############################

$uridlrrid = "https://$NSXIP/api/4.0/edges/$dlrid/routing/config/global"

$dlrridbody = "<routingGlobalConfig>
<routerId>$dlrrouterid</routerId>
</routingGlobalConfig>"

try {
	Write-Host -BackgroundColor:Black -ForegroundColor:Yellow "Status - Configuring Router ID for DLR"
	$result = Invoke-RestMethod -Uri $uridlrrid -Method Put -Headers $header -ContentType "application/xml" -Body $dlrridbody -TimeoutSec 1200 -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - Router ID has been configured for DLR"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
	$responseBody
 }


###############DLR OSPF Configuration ############################

$uridlrospf = "https://$NSXIP/api/4.0/edges/$dlrid/routing/config/ospf"

$dlrospfbody = "<ospf>
<enabled>true</enabled>
<protocolAddress>$dlrprotocoladdress</protocolAddress>
<forwardingAddress>$dlrforwardingaddress</forwardingAddress>
<ospfAreas>
<ospfArea>
<areaId>$ospfareaid</areaId>
</ospfArea>
</ospfAreas>
<ospfInterfaces>
<ospfInterface>
<vnic>2</vnic>
<areaId>$ospfareaid</areaId>
<mtuIgnore>false</mtuIgnore>
</ospfInterface>
</ospfInterfaces>
<redistribution>
<enabled>true</enabled>
<rules>
<rule>
<from>
<isis>false</isis>
<ospf>false</ospf>
<bgp>false</bgp>
<static>false</static>
<connected>true</connected>
</from>
<action>permit</action>
</rule>
</rules>
</redistribution>
</ospf>"

try {
	Write-Host -BackgroundColor:Black -ForegroundColor:Yellow "Status - Configuring OSPF in DLR"
	$result = Invoke-RestMethod -Uri $uridlrospf -Method Put -Headers $header -ContentType "application/xml" -Body $dlrospfbody -TimeoutSec 1200 -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - OSPF has been configured in DLR"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
	$responseBody
 }
Disconnect-VIServer * -Confirm:$false