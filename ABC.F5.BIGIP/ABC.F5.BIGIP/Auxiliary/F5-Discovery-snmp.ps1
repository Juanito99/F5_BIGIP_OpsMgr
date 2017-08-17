
#region PROGRAM_Initialization

$Global:Error.Clear()
$script:ErrorView                   = 'NormalView'
$ErrorActionPreference              = 'Continue'

$tempPath = Get-ItemProperty -Path 'HKLM:\SOFTWARE\ABCIT\F5BigIPMonitoringServer' | Select-Object -ExpandProperty FilePath
$logName  = $tempPath + '\' + $($MyInvocation.MyCommand.Name) + '.log.txt'

if (Test-Path -Path $tempPath) {
  $foo = 'Path exist, no action required.'
} else {
  mkdir -Path $tempPath 
}

Get-ChildItem -Path $tempPath -Filter '*-tmpFile.txt' | Remove-Item -Force

$jsonInventoryFileName = $($MyInvocation.MyCommand.Name)  -replace '.ps1',''

$F5BigIPHosts = Import-Csv -Path $($tempPath + '\' + 'F5-BigIP-Hosts.csv')


#OIDs for SNMPTable 
$oidTables = @{    
  'VirtualServerTable'      = '.1.3.6.1.4.1.3375.2.2.10.1.2'   
  'NodeAddrStatus'          = '.1.3.6.1.4.1.3375.2.2.4.3.2'
  'NodeAddrTable'           = '.1.3.6.1.4.1.3375.2.2.4.1.2'
  'PoolStatus'              = '.1.3.6.1.4.1.3375.2.2.5.5.2'
  'PoolMemberStatus'        = '.1.3.6.1.4.1.3375.2.2.5.6.2'
  'SyncStatusDetails'       = '.1.3.6.1.4.1.3375.2.1.14.2.2'
  'FailOverStatusDetails'   = '.1.3.6.1.4.1.3375.2.1.14.4.2'
  'TrafficGroupStatusTable' = '.1.3.6.1.4.1.3375.2.1.14.5.2'
}

#OIDs for SNMP Walk
$oidWalks = @{
  'GeneralInfo' = '.1.3.6.1.4.1.3375.2.1.6'
  'ProductInfo' = '.1.3.6.1.4.1.3375.2.1.4'
}

#Defines a timeout for every queried OID
$oidTimeOuts = @{
  'VirtualServerTable'      = 60
  'NodeAddrTable'           = 60 
  'NodeAddrStatus'          = 60
  'PoolStatus'              = 30
  'PoolMemberStatus'        = 30
  'SyncStatusDetails'       = 30
  'FailOverStatusDetails'   = 30
  'TrafficGroupStatusTable' = 30
  'GeneralInfo'             = 30
  'ProductInfo'             = 30
}
  
#endregion PROGRAM_Initialization

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


Function Get-SNMPTable {

  param(
    [Parameter(Mandatory=$true)][string]$Oid,
    [Parameter(Mandatory=$true)][string]$F5BigIPHost,
    [Parameter(Mandatory=$true)][string]$infoType,
    [Ref]$cleanOutput,
    [int]$timeOut=$null
  )  

  $rtn = $null
  
  try {
    
    $tmpFile = $tempPath + '\' + "$($F5BigIPHost)-$($infoType)-tmpFile.txt"
    if (Test-Path -Path $tmpFile) {
      Remove-Item -Path $tmpFile -Force
    }       
    
    if ($timeOut -eq 0) {
      $timeOut = 30
    }

    Invoke-Expression "C:\usr\bin\snmptable.exe -v 2c -t $timeOut -c public -Cf *.* $F5BigIPHost $Oid" | Out-File -FilePath $tmpFile
    [string]$snmpTableRaw = Get-Content -Path $tmpFile | Out-String
    
  } catch {
  
    if($Error) {    
      Write-ErrorLog -logName $logName -functionName $($MyInvocation.MyCommand.Name) -err $Error
      $rtn = $false
    } else {
      $foo = 'No need to report error.'
    }    
  
  }
  
  switch ($infoType) {    
    'VirtualServerTable'      { $searchPattern = 'F5-BIGIP-LOCAL-MIB::ltmVirtualServTable' }
    'VirtualServerAddr'       { $searchPattern = 'F5-BIGIP-LOCAL-MIB::ltmVAddrStatusTable' }
    'NodeAddrStatus'          { $searchPattern = 'F5-BIGIP-LOCAL-MIB::ltmNodeAddrStatusTable' }
    'NodeAddrTable'           { $searchPattern = 'F5-BIGIP-LOCAL-MIB::ltmNodeAddrTable' }
    'PoolStatus'              { $searchPattern = 'F5-BIGIP-LOCAL-MIB::ltmPoolStatusTable' }
    'PoolMemberStatus'        { $searchPattern = 'F5-BIGIP-LOCAL-MIB::ltmPoolMbrStatusTable' }    
    'SyncStatusDetails'       { $searchPattern = 'F5-BIGIP-SYSTEM-MIB::sysCmSyncStatusDetailsTable' }
    'FailOverStatusDetails'   { $searchPattern = 'F5-BIGIP-SYSTEM-MIB::sysCmFailoverStatusDetailsTable' }
    'TrafficGroupStatusTable' { $searchPattern = 'F5-BIGIP-SYSTEM-MIB::sysCmTrafficGroupStatusTable' }    
    default {'.'}
  }
  
  $snmpTableRaw     = $snmpTableRaw -replace 'SNMP table:', ''
  $snmpTableRaw     = $snmpTableRaw -replace $searchPattern, ''
           
  $snmpTableRaw     = $snmpTableRaw.TrimStart()
  $snmpTableRows    = $snmpTableRaw.Split("`n",[StringSplitOptions]::RemoveEmptyEntries)             
  $snmpTableHeader  = [Regex]::Split($snmpTableRows[0],'\*\.\*',[StringSplitOptions]::RemoveEmptyEntries)           

  $snmpTableObjList = New-Object -TypeName System.Collections.ArrayList  
  
  for($snmpRowCnt = 1; $snmpRowCnt -lt $snmpTableRows.Count; $snmpRowCnt ++)  {
  
    $snmpTableColumns = [Regex]::Split($snmpTableRows[$snmpRowCnt],'\*\.\*',[StringSplitOptions]::RemoveEmptyEntries)           
    
    $properties = @{}
    for($snmpColCnt = 0; $snmpColCnt -lt $snmpTableColumns.Count; $snmpColCnt++) {
      $properties.Add("$([string]$snmpTableHeader[$snmpColCnt])","$([string]$snmpTableColumns[$snmpColCnt])")
    }
    
    $tblObj = New-Object -TypeName PSObject -Property $properties          
    $null = $snmpTableObjList.Add($tblObj)
      
  }  
   
  $cleanOutput.Value = $snmpTableObjList      
  
  if(($snmpTableObjList.Count -gt 0) -and ($rtn -eq $null)) {
    $rtn = $true
  } else {
    $rtn = $false
  }

  $rtn
   
} #END Function Get-SNMPTable


Function Get-SNMPWalk {

  param(
    [Parameter(Mandatory=$true)][string]$Oid,
    [Parameter(Mandatory=$true)][string]$F5BigIPHost,
    [Parameter(Mandatory=$true)][string]$infoType,
    [Ref]$cleanOutput,
    [int]$timeOut=$null
  )
  
  $rtn = $null

  try {

    $tmpFile = $tempPath + '\' + "$($F5BigIPHost)-$($infoType)-tmpFile.txt"
    if (Test-Path -Path $tmpFile) {
      Remove-Item -Path $tmpFile -Force
    }
    
    if ($timeOut -eq 0) {
      $timeOut = 30
    }
    
    Invoke-Expression "C:\usr\bin\snmpwalk.exe -v 2c -t $timeOut -c public $F5BigIPHost $Oid" | Out-File -FilePath $tmpFile    
    [string]$snmpWalkRaw = Get-Content -Path $tmpFile | Out-String 
    
  } catch {

    if($Error) {    
      Write-ErrorLog -logName $logName -functionName $($MyInvocation.MyCommand.Name) -err $Error
      $rtn = $false
    } else {
      $foo = 'No need to report error.'      
    }    
  
  }
      
  switch ($infoType) {
    'GeneralInfo' { $searchPattern = 'F5-BIGIP-SYSTEM-MIB::sys'}    
    'ProductInfo' { $searchPattern = 'F5-BIGIP-SYSTEM-MIB::sys'}     
    default {'.'}
  }
  
  $snmpWalkRaw  = $snmpWalkRaw -replace $searchPattern, ''
           
  $snmpWalkRaw  = $snmpWalkRaw.TrimStart()
  $snmpWalkRows = $snmpWalkRaw.Split("`n",[StringSplitOptions]::RemoveEmptyEntries)             
  
  $snmpWalkObjList = New-Object -TypeName System.Collections.ArrayList  
  $properties      = @{}

  foreach($snmpWalkRow in $snmpWalkRows) {        
    $snmpWalkColumns = $snmpWalkRow.Split('=',[StringSplitOptions]::RemoveEmptyEntries)
    $propName        = $([string]$snmpWalkColumns[0]).Replace('.0','')
    $propValue       = [REGEX]::Replace( $([string]$snmpWalkColumns[1]),'(STRING:|Gauge32:|Timeticks:|INT:)','',[Text.RegularExpressions.RegexOptions]::IgnoreCase)                   
    $properties.Add($propName,$propValue)
  }

  $wlkObj = New-Object -TypeName PSObject -Property $properties          
  $null   = $snmpWalkObjList.Add($wlkObj)  
  
  $cleanOutput.Value = $snmpWalkObjList  
  if(($snmpWalkObjList.Count -gt 0) -and ($rtn -eq $null))  {
    $rtn = $true
  } else {
    $rtn = $false
  }   
  
  $rtn

} #END Function Get-SNMPWalk


Function Select-SNMPKeyInfo {

  param(
    [Parameter(Mandatory=$true)][Collections.ArrayList]$snmpRawData,
    [Parameter(Mandatory=$true)][string]$infoType    
  )
  
  switch ($infoType) {    
    'VirtualServerTable'      { $requiredProperties = 'ltmVirtualServName,ltmVirtualServVaName,ltmVirtualServPort,ltmVirtualServAvailabilityState,ltmVirtualServEnabled' }
    'VirtualServerAddr'       { $requiredProperties = 'ltmVAddrStatusAvailState,ltmVAddrStatusEnabledState,ltmVAddrStatusName,ltmVAddrStatusDetailReason' }
    'NodeAddrStatus'          { $requiredProperties = 'ltmNodeAddrStatusEnabledState,ltmNodeAddrStatusAvailState,ltmNodeAddrStatusDetailReason,ltmNodeAddrStatusName' }
    'NodeAddrTable'           { $requiredProperties = 'ltmNodeAddrName,ltmNodeAddrStatusReason,ltmNodeAddrMonitorState,ltmNodeAddrSessionStatus,ltmNodeAddrMonitorRule,ltmNodeAddrEnabledState,ltmNodeAddrMonitorStatus' }
    'PoolStatus'              { $requiredProperties = 'ltmPoolStatusEnabledState,ltmPoolStatusDetailReason,ltmPoolStatusName,ltmPoolStatusAvailState' }
    'PoolMemberStatus'        { $requiredProperties = 'ltmPoolMbrStatusAvailState,ltmPoolMbrStatusPoolName,ltmPoolMbrStatusNodeName,ltmPoolMbrStatusDetailReason,ltmPoolMbrStatusEnabledState,ltmPoolMbrStatusPort' }        
    'SyncStatusDetails'       { $requiredProperties = 'sysCmSyncStatusDetailsDetails' }     
    'FailOverStatusDetails'   { $requiredProperties = 'sysCmFailoverStatusDetailsDetails' } 
    'TrafficGroupStatusTable' { $requiredProperties = 'sysCmTrafficGroupStatusDeviceName,sysCmTrafficGroupStatusFailoverStatus,sysCmTrafficGroupStatusTrafficGroup' }    
    'GeneralInfo'             { $requiredProperties = 'SystemRelease,SystemName,SystemNodeName,SystemUptime'}
    'ProductInfo'             { $requiredProperties = 'ProductName,ProductBuild,ProductDate,ProductVersion,ProductEdition,ProductHotfix'}
    default {'.'}
  }
  
  if($snmpRawData -eq $null) {      
    Write-ErrorLog -logName $logName -functionName $($MyInvocation.MyCommand.Name) -err 'snmpRawData is NULL!' 
  } else {
    $foo = 'No need to report error.'    
  }

  $properties = $requiredProperties -split ','
  $filteredObjectList = New-Object -TypeName Collections.ArrayList

  foreach($snmpObj in $snmpRawData) { 
      
    if ($snmpObj -ne $null) {
      
      $snmpObjPairs = $snmpObj.PSObject.Properties | Select-Object -Property @{Name="Name";Expression={$_.Name.Trim()}}, @{Name="Value";Expression={$_.Value.Trim()}}
      $props = @{}

      foreach($snmpObjPair in $snmpObjPairs) {      
      
        foreach($property in $properties) {        
          if($property.Equals($snmpObjPair.Name)) {
            $props.Add($snmpObjPair.Name, $snmpObjPair.Value)                        
            $snmpTargetObj = New-Object -TypeName psobject -Property $props                    
          }      
        } 
      } #END foreach($snmpObjPair in $snmpObjPairs)        
            
      $null = $filteredObjectList.Add($snmpTargetObj)    
      
    }
    
  }

  if($Error) {    
    Write-ErrorLog -logName $logName -functionName $($MyInvocation.MyCommand.Name) -err $Error
  } else {
    $foo = 'No need to report error.'
  }   

  $filteredObjectList 

} #END Function Select-SNMPKeyInfo


#region PROGRAM_MAIN

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
    
    foreach($infoType in $oidTimeOuts.Keys) {
  
        $snmpRaw = New-Object -TypeName System.Collections.ArrayList

        if($oidTables.ContainsKey($infoType)) {      
          $snmpTableRtn = Get-SNMPTable -Oid $oidTables.$infoType -F5BigIPHost $f5HostUrl -infoType $infoType -timeOut $oidTimeOuts.$infoType -cleanOutput([ref]$snmpRaw)
        } elseif ($oidWalks.ContainsKey($infoType)) {      
          $snmpWalkRtn = Get-SNMPWalk -Oid $oidWalks.$infoType -F5BigIPHost $f5HostUrl -infoType $infoType -cleanOutput([ref]$snmpRaw)
        } else {        
          Write-ErrorLog -logName $logName -functionName 'Within foreach(infoType in oidTimeOuts.Keys)' -err "Could not find the $infoType in the OID-Maps."
        }  
        
        if($snmpRaw -eq '' -or $snmpRaw.count -eq 0) {        

          write-host "$infoType - $f5HostUrl"
          write-host "snmpRaw is empty: $($snmpRaw)"
          Write-ErrorLog -logName $logName -functionName 'Withing MAINPROGRAM' -err "Variable snmpParsed is NULL or strange `n $snmpParsed"

        } else {
        
          $snmpParsed = Select-SNMPKeyInfo -snmpRawData $snmpRaw -infoType $infoType
  
          if(($snmpParsed -ne $null) -and (($snmpParsed | Get-Member -MemberType NoteProperty).count -gt 0)) {            
            $invenFilePath = $tempPath + '\' + $f5HostUrl + '_' + $jsonInventoryFileName + '-' + $infoType +'.json'
            $jsono = [PSCustomObject]@{$infoType=$snmpParsed}          
            $jsono | ConvertTo-Json | Out-File -FilePath $invenFilePath -Encoding unicode       
          } else {  
            Write-ErrorLog -logName $logName -functionName 'Withing MAINPROGRAM' -err "Variable snmpParsed is NULL or strange `n $snmpParsed"
          }  

        }        
        
      Start-Sleep -Seconds 5

    } 

  } else {

     Write-ErrorLog -logName $logName -functionName 'Inital test.' -err "BigIP: $($f5HostUrl) not reachable!"
     exit

  } #END if ($f5HostUrl -ne '') 

} #END foreach($f5HostItem in $F5BigIPHosts)


#endregion PROGRAM_MAIN