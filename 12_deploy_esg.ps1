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
$ds = $config.edge.datastore
$dvpg = $config.edge.portgroup

$moref = @{}
$moref.Add("datacenter",(Get-Datacenter $dc | Get-View).MoRef.Value)
$moref.Add("cluster",(Get-Cluster $cluster | Get-View).MoRef.Value)
$moref.Add("datastore",(Get-Datastore $ds | Get-View).MoRef.Value)
$moref.Add("vdspg",(Get-VDPortgroup $dvpg | Get-View).MoRef.Value)
$dcid = $moref.datacenter
$csid = $moref.cluster
$dsid = $moref.datastore
$pgid = $moref.vdspg

####ESG Details #####

$esgname = $config.edge.name
$esgfqdn = $config.edge.fqdn
$esguplinkname = $config.edge.uplinkname
$esguplinkip = $config.edge.uplinkip
$esguplinksubnetmask = $config.edge.uplinksubnetmask
$esguplinksubnetprefixlength = $config.edge.uplinksubnetprefixlength
$esginternalnicname = $config.edge.internalnicname
$esginternalnicip = $config.edge.internalnicip
$esginternalnicsubnetmask = $config.edge.internalnicsubnetmask
$esginternalnicsubnetprefixlength = $config.edge.internalnicsubnetprefixlength
$esgpwd = $config.edge.pass

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

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$uriesg="https://$NSXIP/api/4.0/edges"
$body = "<edge>
  <datacenterMoid>$dcid</datacenterMoid>
  <name>$esgname</name>
  <type>gatewayServices</type>
  <tenant>default</tenant>
  <fqdn>$esgfqdn</fqdn>
  <vseLogLevel>emergency</vseLogLevel>
  <enableAesni>true</enableAesni>
  <enableFips>false</enableFips>
  <appliances>
	<deployAppliances>true</deployAppliances>
    <applianceSize>large</applianceSize>
    <enableCoreDump></enableCoreDump>
    <appliance>
      <resourcePoolId>$csid</resourcePoolId>
      <datastoreId>$dsid</datastoreId>
      </appliance>
  </appliances>
  <vnics>
    <vnic>
      <index>0</index>
      <name>$esguplinkname</name>
      <type>uplink</type>
      <portgroupId>$pgid</portgroupId>
      <addressGroups>
        <addressGroup>
          <primaryAddress>$esguplinkip</primaryAddress>
          <subnetMask>$esguplinksubnetmask</subnetMask>
		  <subnetPrefixLength>$esguplinksubnetprefixlength</subnetPrefixLength>
        </addressGroup>
      </addressGroups>
      <mtu>1500</mtu>
      <enableProxyArp>false</enableProxyArp>
      <enableSendRedirects>false</enableSendRedirects>
      <isConnected>true</isConnected>
      </vnic>
	  <vnic>
		<label>vNic_1</label>
		<name>$esginternalnicname</name>
		<addressGroups>
        <addressGroup>
          <primaryAddress>$esginternalnicip</primaryAddress>
          <subnetMask>$esginternalnicsubnetmask</subnetMask>
		  <subnetPrefixLength>$esginternalnicsubnetprefixlength</subnetPrefixLength>
        </addressGroup>
      </addressGroups>
		<mtu>1500</mtu>
		<type>internal</type>
		<isConnected>true</isConnected>
		<index>1</index>
		<portgroupId>$lsid</portgroupId>
		<portgroupName>$lsname</portgroupName>
		<enableProxyArp>false</enableProxyArp>
		<enableSendRedirects>false</enableSendRedirects>
		</vnic>
  </vnics>
  <cliSettings>
    <userName>admin</userName>
    <password>$esgpwd</password>
    <remoteAccess>true</remoteAccess>
  </cliSettings>
  <autoConfiguration>
    <enabled>true</enabled>
    <rulePriority>high</rulePriority>
  </autoConfiguration>
  <queryDaemon>
    <enabled>false</enabled>
    <port>5666</port>
  </queryDaemon>
</edge>"

##### ESG API Execution #####



try {
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - ESG Deployment Started. This may take about 10-15 mins. Please refer the vSphere Web Client"
	$result = Invoke-RestMethod -Uri $uriesg -Method Post -Headers $header -ContentType "application/xml" -Body $body -TimeoutSec 1200 -ErrorAction:Stop
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
 }
 
$responseBody

Disconnect-VIServer * -Confirm:$false
