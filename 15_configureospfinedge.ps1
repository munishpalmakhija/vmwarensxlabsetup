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



###############Edge Details ############################

$edgrouterid = $config.edge.uplinkip
$ospfareaid = $config.ospf.areaid


$uriedgedetails="https://$NSXIP/api/4.0/edges/?edgeType=gatewayServices"
$edgdetails = Invoke-RestMethod -Uri $uriedgedetails -Method Get -Headers $header -ContentType "application/xml"
$egid = $edgdetails.pagedEdgeList.edgePage.edgeSummary.objectId


###############Edge Router ID Configuration ############################

$uriedgerid = "https://$NSXIP/api/4.0/edges/$egid/routing/config/global"

$edgeridbody = "<routingGlobalConfig>
<routerId>$edgrouterid</routerId>
</routingGlobalConfig>"

try {
	Write-Host -BackgroundColor:Black -ForegroundColor:Yellow "Status - Configuring Router ID for Edge"
	$result = Invoke-RestMethod -Uri $uriedgerid -Method Put -Headers $header -ContentType "application/xml" -Body $edgeridbody -TimeoutSec 1200 -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - Router ID has been configured for Edge"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
	$responseBody
 }


###############Edge OSPF Configuration ############################

$uriedgeospf = "https://$NSXIP/api/4.0/edges/$egid/routing/config/ospf"

$edgeospfbody = "<ospf>
<enabled>true</enabled>
<ospfAreas>
<ospfArea>
<areaId>$ospfareaid</areaId>
</ospfArea>
</ospfAreas>
<ospfInterfaces>
<ospfInterface>
<vnic>1</vnic>
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
	Write-Host -BackgroundColor:Black -ForegroundColor:Yellow "Status - Configuring OSPF in Edge"
	$result = Invoke-RestMethod -Uri $uriedgeospf -Method Put -Headers $header -ContentType "application/xml" -Body $edgeospfbody -TimeoutSec 1200 -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - OSPF has been configured in Edge"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
	$responseBody
 }


Disconnect-VIServer * -Confirm:$false
