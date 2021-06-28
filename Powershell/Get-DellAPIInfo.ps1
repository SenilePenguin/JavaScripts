# Written by Nicholas James, 2021
<#
    Usage:
        Have PDQ Inventory output an Auto Report containing (at minimum) the columns:
        Computer Name (Column: "Name") and 
        Computer Serial Number (Column: "Serial Number")

        This script is recommended to be scheduled once a day via Task Scheduler.
#>

$ApiKey = "API_KEY_HERE"
$KeySecret = "SECRET_KEY_HERE"
$InputCSVFile = "$PSScriptRoot\Dell_Systems_Info.csv"
$OutputCSVFile = "$PSScriptRoot\Dell_Warranty_API_Info.csv"
$PDQInventoryPath = "C:\Program Files (x86)\Admin Arsenal\PDQ Inventory\PDQInventory.exe"
$ServiceTag = [System.Collections.ArrayList]@()

Remove-Item -Force $OutputCSVFile -ErrorAction Ignore
Remove-Variable ServiceTag -ErrorAction Ignore
Remove-Variable Target -ErrorAction Ignore

function Test-FileLock {
    param (
        [parameter(Mandatory = $true)][string]$Path
    )
  
    $oFile = New-Object System.IO.FileInfo $Path

    # If the file doesn't exist, it can't be locked!
    if ((Test-Path -Path $Path) -eq $false) { return $false }
  
    # If we fail to open the file with read/write access, it is more than likely locked
    try {
        $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
  
        if ($oStream) {
            $oStream.Close()
        }
        return $false
    } catch {
        # file is locked by a process.
        return $true
    }
}

# As this script is designed to be run on a schedule automatically, we need to ensure the output file is available.
$waitCounter = 0
$waitThreshold = 360 # 3600 seconds / 10 second wait = 1 hour
while ( ($waitCounter -lt $waitThreshold) -and (Test-FileLock -Path $OutputCSVFile) ) {
    $waitCounter++
    Write-Output "File is locked! ($waitCounter/$waitThreshold)"

    if ($waitCounter -eq $waitThreshold) {
        Write-Output "Timeout threshold reached. Aborting!"
        exit 
    }

    # If we didn't exit, wait a short time and test again
    Start-Sleep -Seconds 10
}

# If an authorization token is not currently cached, generate a new one.
if (!$token) {
    $AuthURI = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token"
    $OAuth = "$ApiKey`:$KeySecret"
    $Bytes = [System.Text.Encoding]::ASCII.GetBytes($OAuth)
    $EncodedOAuth = [Convert]::ToBase64String($Bytes)
    $Headers = @{ }
    $Headers.Add("authorization", "Basic $EncodedOAuth")
    $Authbody = 'grant_type=client_credentials'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $AuthResult = Invoke-RestMethod -Method Post -Uri $AuthURI -Body $AuthBody -Headers $Headers
    $token = $AuthResult.access_token
    $headers = @{"Accept" = "application/json" }
    $headers.Add("Authorization", "Bearer $token")
}

$CSVInput = Import-Csv $InputCSVFile
$discoveredCount = @(Get-Content $InputCSVFile).Length - 1
Write-Output "Detected $discoveredCount entries!"

$namesMap = @{}
$serialsString = ""
$linesCounter = 0
$linesPasses = 0

# Generate a serial string consisting of 100 serial numbers and query the API
foreach ($line in $CSVInput) {
    $linesCounter++
    #Write-Output "$($line.Name) - $($line."Serial Number")"
    $namesMap.Add($line."Serial Number" , $line.Name)
    $serialsString += "$($line."Serial Number"),"

    # API only accepts 100 at a time, so only send an API request every 100
    if ($linesCounter -eq 100) {
        $linesPasses++
        Write-Output "Sending API Request: $linesPasses ($(($linesPasses-1)*100+1)-$($linesPasses*100)/$discoveredCount)"
        $serialsString = $serialsString.Trim(",")

        $params = @{}
        $params = @{servicetags = $serialsString; Method = "GET" }
        $response = Invoke-RestMethod -Uri "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements" -Headers $headers -Body $params -Method Get -ContentType "application/json" -ea 0

        # All JSON objects returned are below. Some are not used, but are below in case you want them.
        foreach ($l in $response) {
            #$res_id = $l.id
            $ServiceTag = $l.servicetag
            #$res_orderBuid = $l.orderBuid
            $ShipDate = $l.shipDate | Get-Date -Format "MM-dd-yyyy" -ErrorAction SilentlyContinue
            #$res_productCode = $l.productCode
            #$res_localChannel = $l.localChannel
            $ProductID = $l.productId
            $Device = $l.productLineDescription
            #$res_productFamily = $l.productFamily
            $SystemDescription = $l.systemDescription
            $ProductLobDescription = $l.productLobDescription
            #$res_countryCode = $l.countryCode
            #$res_duplicated = $l.duplicated
            #$res_invalid = $l.invalid
            #$res_entitlements = $l.entitlements
    
            if ($ProductID -Like '*desktop*') { $ProductID += ' (Desktop)' }
            elseif ($ProductID -Like '*laptop*') { $ProductID += ' (Laptop)' }
        
            $EndDate = ($l.entitlements | Select-Object -Last 1).endDate | Get-Date -Format "MM-dd-yyyy" -ErrorAction SilentlyContinue
            $today = Get-Date
            $Expired = $today -ge $EndDate
            
            #Build new object for output CSV file
            $csvLine = [PSCustomObject]@{
                Name              = $namesMap[$ServiceTag]
                ServiceTag        = $ServiceTag
                WarrantyStartDate = $(if ($null -eq $ShipDate) { "01/01/1990" | Get-Date -Format "MM/dd/yyyy" } else { $ShipDate } )
                WarrantyEndDate   = $(if ($null -eq $EndDate) { "01/01/1990" | Get-Date -Format "MM/dd/yyyy" } else { $EndDate } )
                WarrantyExpired   = $Expired
                ProductID         = $ProductID
                DeviceModel       = $Device
                SystemDescription = $SystemDescription
                Family            = $ProductLobDescription
            }

            #Append new line to output CSV file
            $csvLine | Export-Csv -Path $OutputCSVFile -Append -NoTypeInformation
        }

        $serialsString = ""
        $linesCounter = 0
        # Increase this delay if you have very large amounts of systems are are encountering rate-limiting.
        # Start-Sleep -Seconds 1
    }
}

# Import new properties to PDQInventory
# https://www.pdq.com/blog/adding-custom-fields-multiple-computers-powershell/
& $PDQInventoryPath ImportCustomFields -FileName $OutputCSVFile -ComputerColumn "Name" -CustomFields "WarrantyStartDate=Purchase Date,WarrantyEndDate=Warranty End Date,WarrantyExpired=Warranty Expired" -AllowOverwrite
