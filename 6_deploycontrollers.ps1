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

##### Datacenter ID #####

$dc = $config.vsphere.dcname
$moref = @{}
$moref.Add("datacenter",(Get-Datacenter $dc | Get-View).MoRef.Value)
$dcid = $moref.datacenter

##### IPPool API Config #####

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$uri="https://$NSXIP/api/2.0/services/ipam/pools/scope/$dcid"


##### IPPool API Execution #####

$ippool = Invoke-RestMethod -Uri $uri -Method Get -Headers $header -ContentType "application/xml"

##### IPPool API Output #####

$ippoolids = $ippool.ipamAddressPools.ipamAddressPool.objectId

$ippoolid = $ippoolids

##### Controller API Body Details ####

$cluster = $config.vsphere.clustername
$ds = $config.vsphere.controllerdatastore
$dvpg = $config.vsphere.controllerportgroup
$moref = @{}
$moref.Add("cluster",(Get-Cluster $cluster | Get-View).MoRef.Value)
$moref.Add("datastore",(Get-Datastore $ds | Get-View).MoRef.Value)
$moref.Add("vdspg",(Get-VDPortgroup $dvpg | Get-View).MoRef.Value)
$csid = $moref.cluster
$dsid = $moref.datastore
$pgid = $moref.vdspg
$ctrlpwd = $config.controllers.pass
$ctrl01name = $config.controllers.name

##### Controller API Config #####

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$uri="https://$NSXIP/api/2.0/vdn/controller"
$body = "<controllerSpec>
<name>$ctrl01name</name>
<description>nsx-controller</description>
<ipPoolId>$ippoolid</ipPoolId>
<resourcePoolId>$csid</resourcePoolId>
<datastoreId>$dsid</datastoreId>
<deployType>medium</deployType>
<networkId>$pgid</networkId>
<password>$ctrlpwd</password>
</controllerSpec>"

##### Controller API Execution #####


try {
        $result = Invoke-RestMethod -Uri $uri -Method Post -Headers $header -ContentType "application/xml" -Body $body -TimeoutSec 1200 -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - Deployment of the NSX Controller has Started.Please refer the vSphere Web Client for the exact Status !!!"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
 }
 
$responseBody

Disconnect-VIServer * -Confirm:$false

