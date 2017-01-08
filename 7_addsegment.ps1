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

##### NSX Segment Details #####

$segname = $config.nsxsegment.name
$segstartid = $config.nsxsegment.startid
$segendid = $config.nsxsegment.endid

##### IPPool API Config #####

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$uri="https://$NSXIP/api/2.0/vdn/config/segments"
$body = "<segmentRange> <name>$segname</name> <begin>$segstartid</begin> <end>$segendid</end> </segmentRange>"

##### SegmentID API Execution #####

try {
        $result = Invoke-RestMethod -Uri $uri -Method Post -Headers $header -ContentType "application/xml" -Body $body -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - Segment ID Created. Please refer the vSphere Web Client and Confirm !!!"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
 }
 
$responseBody

Disconnect-VIServer * -Confirm:$false
