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

##### VC Details #####

$dc = $config.vsphere.dcname
$cluster = $config.vsphere.clustername
$ds = $config.dlr.datastore
$moref = @{}
$moref.Add("datacenter",(Get-Datacenter $dc | Get-View).MoRef.Value)
$moref.Add("cluster",(Get-Cluster $cluster | Get-View).MoRef.Value)
$moref.Add("datastore",(Get-Datastore $ds | Get-View).MoRef.Value)
$dcid = $moref.datacenter
$csid = $moref.cluster
$dsid = $moref.datastore

####DLR Details #####

$dlrname = $config.dlr.name
$dlrfqdn = $config.dlr.fqdn
$dlruplinkname = $config.dlr.uplinkname
$dlruplinkip = $config.dlr.uplinkip
$dlruplinksubnetmask = $config.dlr.uplinksubnetmask
$dlrsubnetprefixlength = $config.dlr.uplinksubnetprefixlength
$dlrpwd = $config.dlr.pass

##### Generate Scope ID via API Config #####

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$uri="https://$NSXIP/api/2.0/vdn/scopes"

##### Scope ID API Execution #####

$scopeid = Invoke-RestMethod -Uri $uri -Method Get -Headers $header -ContentType "application/xml"

$sid = $scopeid.vdnScopes.vdnScope.id


##### Logical Switch API Execution #####

$urils="https://$NSXIP/api/2.0/vdn/scopes/$sid/virtualwires"

$ls = Invoke-RestMethod -Uri $urils -Method Get -Headers $header -ContentType "application/xml"

$lsid = $ls.VirtualWires.dataPage.virtualWire.objectId
$lsname = $ls.VirtualWires.dataPage.virtualWire.Name
$lspgid = $ls.VirtualWires.dataPage.virtualWire.vdsContextwithBacking.backingValue

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$uridlr="https://$NSXIP/api/4.0/edges"

$body = "<edge>
	<datacenterMoid>$dcid</datacenterMoid>
	<datacenterName>$dc.Name</datacenterName>
	<tenant>default</tenant>
	<name>$dlrname</name>
	<fqdn>$dlrfqdn</fqdn>
	<enableAesni>true</enableAesni>
	<enableFips>false</enableFips>
	<vseLogLevel>emergency</vseLogLevel>
	<type>distributedRouter</type>
	<isUniversal>false</isUniversal>
	<hypervisorAssist>false</hypervisorAssist>
	<queryDaemon>
	<enabled>false</enabled>
	<port>5666</port>
	</queryDaemon>
	<mgmtInterface>
    <connectedToId>$lspgid</connectedToId>
    </mgmtInterface>
	<appliances>
    <deployAppliances>true</deployAppliances>
    <applianceSize>large</applianceSize>
    <enableCoreDump>false</enableCoreDump>
    <appliance>
      <resourcePoolId>$csid</resourcePoolId>
      <datastoreId>$dsid</datastoreId>
    </appliance>
    </appliances>
	<interfaces>
	<interface>
	<label>vNic_0</label>
	<name>$dlruplinkname</name>
	<addressGroups>
	<addressGroup>
	<primaryAddress>$dlruplinkip</primaryAddress>
	<subnetMask>$dlruplinksubnetmask</subnetMask>
	<subnetPrefixLength>$dlrsubnetprefixlength</subnetPrefixLength>
	</addressGroup>
	</addressGroups>
	<mtu>1500</mtu>
	<type>uplink</type>
	<isConnected>true</isConnected>
	<connectedToId>$lsid</connectedToId>
	<connectedToName>$lsname</connectedToName>
	</interface>
	</interfaces>
	<cliSettings>
	<remoteAccess>true</remoteAccess>
	<userName>admin</userName>
	<password>$dlrpwd</password>
	</cliSettings>
	<autoConfiguration>
	<enabled>true</enabled>
	<rulePriority>high</rulePriority>
	</autoConfiguration>
</edge>"

##### DLR API Execution #####

try {
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - DLR Deployment Started. This may take about 10-15 mins. Please refer the vSphere Web Client"
        $result = Invoke-RestMethod -Uri $uridlr -Method Post -Headers $header -ContentType "application/xml" -Body $body -TimeoutSec 1200 -ErrorAction:Stop

}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
 }
 
$responseBody

Disconnect-VIServer * -Confirm:$false