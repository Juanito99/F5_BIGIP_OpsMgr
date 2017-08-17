#region PREWORK Disabling the certificate validations
add-type -TypeDefinition @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[Net.ServicePointManager]::CertificatePolicy = New-Object -TypeName TrustAllCertsPolicy
#endregion PREWORK


#region  PROGRAM_initialization

$Global:Error.Clear()
$script:ErrorView      = 'NormalView'
$ErrorActionPreference = 'Continue'

$User  = Get-ItemProperty -Path 'HKLM:\SOFTWARE\ABCIT\F5BigIPMonitoringServer' | Select-Object -ExpandProperty RESTUsr
$Pass  = Get-ItemProperty -Path 'HKLM:\SOFTWARE\ABCIT\F5BigIPMonitoringServer' | Select-Object -ExpandProperty RESTPwd
$AUTH_TOKEN = $null
    
$restURIs = @{
  'Disk'     = '/mgmt/tm/sys/disk/logical-disk'
  'Memory'   = '/mgmt/tm/sys/memory'
  'CPU'      = '/mgmt/tm/sys/cpu'
  'Services' = '/mgmt/tm/sys/ha-status/stats?options=all-properties'
}

$tempPath = Get-ItemProperty -Path 'HKLM:\SOFTWARE\SIGIT\F5BigIPMonitoringServer' | Select-Object -ExpandProperty FilePath
$logName  = $tempPath + '\' + $($MyInvocation.MyCommand.Name) + '.log.txt'

if (Test-Path -Path $tempPath) {
  $foo = 'Path exist, no action required.'
} else {
  mkdir -Path $tempPath 
}

$F5BigIPHosts = Import-Csv -Path $($tempPath + '\' + 'F5-BigIP-Hosts.csv')

$jsonInventoryFileName = $($MyInvocation.MyCommand.Name)  -replace '.ps1',''

"Start Logging on $(Get-Date)" | Out-File -FilePath $logName 
$jsonInventoryFilePrefix = $tempPath + '\' + $($MyInvocation.MyCommand.Name) 
$jsonInvetoryFileSuffix  = '.json'

$sProperties = @{"F5-REST-Discovery-Start"="$(Get-Date)"}
$startObj    = New-Object -TypeName psobject -Property $sProperties
  

#endregion  PROGRAM_initialization 


Function Write-ErrorLog {

  param (
    [Parameter(Mandatory=$true)]
    [string]$functionName,    
    [Parameter(Mandatory=$true)]
    [string]$logName,
    [Parameter(Mandatory=$true)]
    [Object]$err=$null
  )

  
  if($err) {
    "Function-Name: $($functionName) Err: $($err)" | Out-File -FilePath $logName -Append
  } else {
    "Function-Name: $($functionName)" | Out-File -FilePath $logName -Append  
  }

  $Error `
  | Group-Object `
  | Sort-Object -Property Count -Descending `
  | Format-Table -Property Count,Name -AutoSize | Out-File -FilePath $logName -Append    

  if($Error[0].Exception.InnerException) {
    $Error[0].Exception.InnerException | Out-File -FilePath $logName -Append
  }

  "`n`n" | Out-File -FilePath $logName -Append
  $Error.Clear()
  
} #END Function Write-ErrorLog


function Get-AuthToken() {

  $token = $null
  
  if ( $null -ne $AUTH_TOKEN ) {
    $token = $AUTH_TOKEN
  } else {
    $uri   = "/mgmt/shared/authn/login"    
    $link  = "https://" + $F5BigIPHost + $uri

    $headers = @{}
    $body    = "{'username':'$User','password':'$Pass','loginProviderName':'tmos'}"
     
    $obj   = Invoke-RestMethod -Method POST -Headers $headers -Uri $link -Body $body
    $token = $obj.token.token
  }

  return $token

} #END Get-AuthToken()
 

function Get-RESTValues() {

  param (
    [Parameter(Mandatory=$true)]
    [string]$uri,
    [string]$F5BigIPHost,    
    [ref]$cleanOutPut
  )

  $rtn = $null
  
  $link    = "https://" + $F5BigIPHost + $uri
  $headers = @{}
  $headers.Add("X-F5-Auth-Token", $(Get-AuthToken))
  
  try {
  
    $obj = Invoke-RestMethod -Method GET -Headers $headers -Uri $link
    $cleanOutPut.Value = $obj    
      
  } catch {
  
    if($Error) {    
      Write-ErrorLog -logName $logName -functionName $($MyInvocation.MyCommand.Name) -err $Error
      $rtn = $false
    } else {
      $foo = 'No need to report error.'
    }    

  }
  
  if($obj -and $rtn -eq $null) {
    $rtn = $true
  } else {
    $rtn = $false
  } 
  
  $rtn       
 
} #END function Get-RESTValues


#region MAIN_Program

foreach($f5HostItem in $F5BigIPHosts) {
  
  $f5HostName      = ''
  $f5HostIPAddress = ''
  $f5HostUrl       = ''

  if ($f5HostItem.HostName -match '[a-zA-Z0-9]{3,}') {
    $f5HostName = $f5HostItem.HostName
  }

  if ($f5HostItem.IPAddress -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}') {
    $f5HostIPAddress = $f5HostItem.IPAddress
  }

  if ($f5HostName -ne '') {
    if (Test-Connection -ComputerName $f5HostName -Count 2 -Quiet) {
      $f5HostUrl = $f5HostName
    }
  }
   
   if (($f5HostUrl -eq '') -and ($f5HostIPAddress -ne '')) {
    if (Test-Connection -ComputerName $f5HostIPAddress -Count 2 -Quiet) {     
      $f5HostUrl = $f5HostIPAddress
    } 
   }     
  
  if ($f5HostUrl -ne '') {
  
    $webInterfaceStatusCode = $(Invoke-WebRequest -Uri "https://$f5HostUrl/").StatusCode 

    if ( $webInterfaceStatusCode -eq 200 ) {
      
      #region GET-DISKS
      $F5Disks          = New-Object -TypeName System.Collections.ArrayList
      $tmpObject        = New-Object Object
      $rtnGetRestValues = Get-RESTValues -uri $restURIs.Disk -cleanOutPut([ref]$tmpObject) -F5BigIPHost $f5HostUrl
      $tmpObject.Items | ForEach-Object {
        $disk = [PSCustomObject]@{
          'FullPath'  = $_.fullPath
          'TotalSize' = $_.size
          'Free'      =  $_.vgFree
          'InUse'     = $_.vgInUse
        }
        $null = $F5Disks.Add($disk)
      }      
      #endregion GET-DISKS  

      #region GET-MEMORY      
      $tmpObject        = New-Object Object
      $rtnGetRestValues = Get-RESTValues -uri $restURIs.Memory -cleanOutPut([ref]$tmpObject) -F5BigIPHost $f5HostUrl
    
      $memoryTotal = $tmpObject.entries.'https://localhost/mgmt/tm/sys/memory/memory-host'.nestedStats.entries.'https://localhost/mgmt/tm/sys/memory/memory-host/0'.nestedStats.entries.memoryTotal.value
      $memoryUsed  = $tmpObject.entries.'https://localhost/mgmt/tm/sys/memory/memory-host'.nestedStats.entries.'https://localhost/mgmt/tm/sys/memory/memory-host/0'.nestedStats.entries.memoryUsed.value
      $memoryFree  = $tmpObject.entries.'https://localhost/mgmt/tm/sys/memory/memory-host'.nestedStats.entries.'https://localhost/mgmt/tm/sys/memory/memory-host/0'.nestedStats.entries.memoryFree.value
            
      $F5Memory = [PSCustomObject]@{
        'MemoryTotal'       = $memoryTotal
        'MemoryUsed'        = $memoryUsed
        'MemoryFree'        = $memoryFree
        'MemoryUsedPercent' = [int](($memoryUsed / $memoryTotal) * 100)
      }           
      #endregion GET-MEMORY    

      #region GET-CPU    
      $F5CPUs           = New-Object System.Collections.ArrayList
      $tmpObject        = New-Object Object
      $rtnGetRestValues = Get-RESTValues -uri $restURIs.CPU -cleanOutPut([ref]$tmpObject) -F5BigIPHost $f5HostUrl

      $entries = $tmpObject.entries.'https://localhost/mgmt/tm/sys/cpu/0'.nestedStats.entries.'https://localhost/mgmt/tm/sys/cpu/0/cpuInfo'.nestedStats.entries

      $entries | ForEach-Object {  
  
        $entryCollection = $_
        $(($entryCollection |Get-Member -MemberType Properties).Name) | ForEach-Object {
  
          $subEntryName      = $_
          $subEntryCPUId     = $entryCollection.$subEntryName.nestedStats.entries.cpuId.value      
          $subEntryAvgIdle   = $entryCollection.$subEntryName.nestedStats.entries.fiveMinAvgIdle.value
          $subEntryAvgSystem = $entryCollection.$subEntryName.nestedStats.entries.fiveMinAvgSystem.value
          $subEntryAvgUser   = $entryCollection.$subEntryName.nestedStats.entries.fiveMinAvgUser.value

          $F5CPU = [PSCustomObject] @{
            'CPUId'  = $subEntryCPUId
            'Idle'   = $subEntryAvgIdle
            'System' = $subEntryAvgSystem
            'User'   = $subEntryAvgUser
          }        

          $null = $F5CPUs.Add($F5CPU)

        } # END $(($entryCollection |Get-Member -MemberType Properties).Name) | ForEach-Object  {}

      } #END $entries | ForEach-Object {}  
      #endregion GET-CPU        

      #region GET-SERVICES
      $F5Services       = New-Object System.Collections.ArrayList
      $tmpObject        = New-Object Object
      $rtnGetRestValues = Get-RESTValues -uri $restURIs.Services -cleanOutPut([ref]$tmpObject) -F5BigIPHost $f5HostUrl   

      $tmpObject.entries | ForEach-Object {  
  
        $entryCollection = $_
  
        $(($entryCollection |Get-Member -MemberType Properties).Name) | ForEach-Object {  

          $subEntryName        = $_
          $subEntryKey         = $entryCollection.$subEntryName.nestedStats.entries.key.description
          $subEntryrespProcess = $entryCollection.$subEntryName.nestedStats.entries.respProcess.description
          $subEntryStatus      = $entryCollection.$subEntryName.nestedStats.entries.enabled.description

          $F5Service = [PSCustomObject] @{
            'Key'     = $subEntryKey
            'Process' = $subEntryrespProcess
            'Status'  = $subEntryStatus          
          }
        
          $null = $F5Services.Add($F5Service)

        } #END $(($entryCollection |Get-Member -MemberType Properties).Name) | ForEach-Object {}  
    
      } #END $tmpObject.entries | ForEach-Object {}        
      #endregion GET-SERVICES    

      #region WRITE-TO-JSON-File    
      $json = [PSCustomObject] @{'F5Disks' = $F5Disks}
      $invenFilePath = $tempPath + '\' + $f5HostUrl + '_' + $jsonInventoryFileName + '-' + 'Disks' + '.json'
      $json | ConvertTo-Json | Out-File -FilePath $invenFilePath -Encoding unicode

      $json = [PSCustomObject] @{'F5Memory'= $F5Memory}
      $invenFilePath = $tempPath + '\' + $f5HostUrl + '_' + $jsonInventoryFileName + '-' + 'Memory' + '.json'
      $json | ConvertTo-Json | Out-File -FilePath $invenFilePath -Encoding unicode 

      $json = [PSCustomObject] @{'F5CPU' = $F5CPUs}
      $invenFilePath = $tempPath + '\' + $f5HostUrl + '_' + $jsonInventoryFileName + '-' + 'CPUs' + '.json'
      $json | ConvertTo-Json | Out-File -FilePath $invenFilePath -Encoding unicode         

      $json = [PSCustomObject] @{'F5Services' = $F5Services}
      $invenFilePath = $tempPath + '\' + $f5HostUrl + '_' + $jsonInventoryFileName + '-' + 'Services' + '.json'
      $json | ConvertTo-Json | Out-File -FilePath $invenFilePath -Encoding unicode                           
      #endregion WRITE-TO-JSON-File

    } else {
  
      Write-ErrorLog -logName $logName -functionName $($MyInvocation.MyCommand.Name) -err "Statuscode other than 200 returned. - StatusCode: $webInterfaceStatusCode"
  
    } #END if ( $webInterfaceStatusCode -eq 200 )
  
  } #END if ($f5HostUrl -ne '') 

} #END foreach($f5HostItem in $F5BigIPHosts)

#endregion MAIN_Program