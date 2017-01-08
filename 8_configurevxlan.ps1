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
$dvs = $config.vds.name
$vlanid = $config.vxlan.vlanid
$teaming = $config.vxlan.teaming
$mtu = $config.vxlan.mtu
$niccount = $config.vxlan.nicCount

$moref = @{}
$moref.Add("vds",(Get-VDSwitch $dvs | Get-View).MoRef.Value)
$moref.Add("datacenter",(Get-Datacenter $dc | Get-View).MoRef.Value)
$moref.Add("cluster",(Get-Cluster $cluster | Get-View).MoRef.Value)

$cid = $moref.cluster
$vdsid = $moref.vds
$dcid = $moref.datacenter


##### IPPool API Config #####

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$uri="https://$NSXIP/api/2.0/services/ipam/pools/scope/$dcid"


##### IPPool API Execution #####

$ippool = Invoke-RestMethod -Uri $uri -Method Get -Headers $header -ContentType "application/xml"

##### IPPool API Output #####

$ippoolid = $ippool.ipamAddressPools.ipamAddressPool.objectId

##### VXLAN API Config ####

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$uri="https://$NSXIP/api/2.0/nwfabric/configure"

$body = "<nwFabricFeatureConfig> 
<featureId>com.vmware.vshield.vsm.vxlan</featureId> 
<resourceConfig> 
<resourceId>$cid</resourceId> 
<configSpec class=`"clusterMappingSpec`"> 
<switch> 
<objectId>$vdsid</objectId> 
</switch> 
<vlanId>$vlanid</vlanId> 
<vmknicCount>$niccount</vmknicCount> 
<ipPoolId>$ippoolid</ipPoolId> </configSpec> 
</resourceConfig> 
<resourceConfig> 
<resourceId>$vdsid</resourceId> 
<configSpec class=`"vdsContext`"> 
<switch> 
<objectId>$vdsid</objectId> 
</switch> <mtu>$mtu</mtu> 
<teaming>$teaming</teaming> 
</configSpec> 
</resourceConfig> 
</nwFabricFeatureConfig>"

##### VXLAN API Execution #####

try {
        $result = Invoke-RestMethod -Uri $uri -Method Post -Headers $header -ContentType "application/xml" -Body $body -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - VXLAN Configuration has been Started. Please refer the vSphere Web Client for Installation Status !!!"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - Something went wrong. Please try again  !!!"
	$responseBody
 }
 
Disconnect-VIServer * -Confirm:$false

