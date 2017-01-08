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

### Ignore TLS/SSL errors
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
public bool CheckValidationResult(
ServicePoint srvPoint, X509Certificate certificate,
WebRequest request, int certificateProblem) {
return true;
}}
"@
 
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

### GET SSL THUMPRINT

Function Get-SSLThumbprint {
    param(
    [Parameter(
        Position=0,
        Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ]
    [Alias('FullName')]
    [String]$URL
    )

    # Need to connect using simple GET operation for this to work
    Invoke-RestMethod -Uri $URL -Method Get | Out-Null

    $ENDPOINT_REQUEST = [System.Net.Webrequest]::Create("$URL")
    $SSL_THUMBPRINT = $ENDPOINT_REQUEST.ServicePoint.Certificate.GetCertHashString()

    return $SSL_THUMBPRINT -replace '(..(?!$))','$1:'
}
# vCenter Server URL
$vcip = $config.vsphere.vcenterip
$vcurl = "https://$vcip"

# Example output

$vctp = Get-SSLThumbprint $vcurl


 
### Create authorization string and store in $head
$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Username + ":" + $NSXPass))
$head = @{"Authorization"="Basic $auth"}
 
# Here we have the request to configure vcenter with NSX
 
$Request = "https://$NSXIP/api/2.0/services/vcconfig"
 
# Here we create the body of how the request needs to be passed, as per the api guide.
 
$body = "<vcInfo>
<ipAddress>$vCenterIP</ipAddress>
<userName>$vcuser</userName>
<password>$vcpass</password>
<assignRoleToUser>true</assignRoleToUser>
<certificateThumbprint>$vctp</certificateThumbprint>
</vcInfo>"
 
### Connect to NSX Manager via API
 
# Here we use a try catch to catch any exceptions which may occur from Invoke-Webrequest
 
try {
        $result = Invoke-WebRequest -Uri $Request -Headers $head -ContentType "application/xml" -Method PUT -ErrorAction:Stop -Body $body
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - VC has been successfully registered. Please refer the vSphere Web Client"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
 }
 
$responseBody

Disconnect-VIServer * -Confirm:$false

