##### JSON Details #####

$jsonpath = "C:\Scripts\infradetails.json"
$config = Get-Content -Raw -Path $jsonpath | ConvertFrom-Json

##### VC Connection #####

Connect-VIServer $config.vsphere.vcenterip -User $config.vsphere.vcuser -Password $config.vsphere.vcpass | Out-Null

$NSXIP = $config.nsx.ip
$NSXPass = $config.nsx.pass

##### Generate Scope ID via API Config #####

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$uri="https://$NSXIP/api/2.0/vdn/scopes"

##### Scope ID API Execution #####

$scopeid = Invoke-RestMethod -Uri $uri -Method Get -Headers $header -ContentType "application/xml"

$sid = $scopeid.vdnScopes.vdnScope.id

##### Logical Switch API Execution #####
$lsname = $config.logicalswitch.name
$description = $config.logicalswitch.description
$tenantid = "virtual wire tenant"

$body = "<virtualWireCreateSpec>
  <name>$lsname</name>
  <description>$description</description>
  <tenantId>$tenantid</tenantId>
</virtualWireCreateSpec>"
$urils="https://$NSXIP/api/2.0/vdn/scopes/$sid/virtualwires"

##### LS API Execution #####

try {
        $result = Invoke-RestMethod -Uri $urils -Method Post -Headers $header -ContentType "application/xml" -Body $body -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - Logical Switch ($lsname) has been Created. Please refer the vSphere Web Client !!!"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
 }
 
$responseBody

Disconnect-VIServer * -Confirm:$false