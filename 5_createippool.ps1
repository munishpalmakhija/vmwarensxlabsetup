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

##### IPPool details #####

$ippoolname = $config.ippool.name
$ippoolprefixlength = $config.ippool.prefixlength
$ippoolgateway = $config.ippool.gateway
$ippooldnssuffix = $config.ippool.dnssuffix
$ippooldnsserver01 = $config.ippool.dnsserver01
$ippooldnsserver02 = $config.ippool.dnsserver02
$ippoolstartipaddress = $config.ippool.startipaddress
$ippoolendipaddress = $config.ippool.endipaddress

##### IPPool API Config #####

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "admin",$NSXPass)))
$header = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$uri="https://$NSXIP/api/2.0/services/ipam/pools/scope/$dcid"
$body = "<ipamAddressPool> <name>$ippoolname</name> <prefixLength>$ippoolprefixlength</prefixLength> <gateway>$ippoolgateway</gateway> <dnsSuffix>$ippooldnssuffix</dnsSuffix> <dnsServer1>$ippooldnsserver01</dnsServer1> <dnsServer2>$ippooldnsserver02</dnsServer2> <ipRanges> <ipRangeDto> <startAddress>$ippoolstartipaddress</startAddress> <endAddress>$ippoolendipaddress</endAddress> </ipRangeDto> </ipRanges> </ipamAddressPool>"

##### IPPool API Execution #####


try {
        $result = Invoke-RestMethod -Uri $uri -Method Post -Headers $header -ContentType "application/xml" -Body $body -ErrorAction:Stop
	Write-Host -BackgroundColor:Black -ForegroundColor:Green "Status - IP Pool has been created successfully !!!"
}
catch {
       $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd();
 }
 
$responseBody

Disconnect-VIServer * -Confirm:$false



