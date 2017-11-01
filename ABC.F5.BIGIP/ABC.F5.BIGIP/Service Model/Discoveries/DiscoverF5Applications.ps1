param($sourceId,$managedEntityId,$discoveryItem,$tempPath)

$api           = New-Object -ComObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

$Global:Error.Clear()
$script:ErrorView      = 'NormalView'
$ErrorActionPreference = 'Continue'

$F5BigIPHosts          = Import-Csv -Path $($tempPath + '\' + 'F5-BigIP-Hosts.csv')
$discoveryFiles        = Get-ChildItem -Path $tempPath -Filter '*F5-Discovery-*.json' | Select-Object -ExpandProperty Name


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
				
		if($discoveryItem -eq 'Info') {
		  $discoveryFileContent = @()
		  $discoveryFile = $discoveryFiles | Where-Object { ($_ -match $discoveryItem) -and ($_ -match $f5HostUrl)}
		  foreach($dFile in $discoveryFile) {
			  $discoveryFileContent += Get-Content -Path $($tempPath + '\' + $dFile) | ConvertFrom-Json
		  }  
		} else {
		  $discoveryFile        = $discoveryFiles | Where-Object { ($_ -match $discoveryItem) -and ($_ -match $f5HostUrl)}
		  $discoveryFileContent = Get-Content -Path $($tempPath + '\' + $discoveryFile) | ConvertFrom-Json
		}

		$discoverySystemFile        = $discoveryFiles | Where-Object {($_ -match 'GeneralInfo') -and ($_ -match $f5HostUrl)}
		$discoverySystemFileContent = Get-Content -Path $($tempPath + '\' + $discoverySystemFile) | ConvertFrom-Json
		$systemNodeNameKey          = $($discoverySystemFileContent.GeneralInfo.SystemNodeName)
				
		if ($discoveryItem -eq 'PoolStatus') {			

			$discoveryFileContent.PoolStatus | ForEach-Object {		  
				$poolName         = $_.ltmPoolStatusName
				$displayName      = 'F5-Pool ' + $poolName + ' On ' + $systemNodeNameKey
				$key              = $systemNodeNameKey + 'F5-Pool' + $poolName
				$poolEnabledState = $_.ltmPoolStatusEnabledState

				if ($_.ltmPoolStatusName) {
					$instance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']$")			
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/PoolStatusEnabledState$",$poolEnabledState)	
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/PoolStatusName$",$poolName)	
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/SystemNodeName$",$systemNodeNameKey)	
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/Key$",$key)
					$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)		
					$discoveryData.AddInstance($instance)
				}
			} #END $discoveryFileContent.PoolStatus | ForEach-Object {}

		} elseif ($discoveryItem -eq 'NodeAddrTable') {
			
			$discoveryFileContent.NodeAddrTable | ForEach-Object {				
				$nodeAddressName          = $_.ltmNodeAddrName
				$displayName              = 'F5-NodeAddress ' + $nodeAddressName + ' On ' + $systemNodeNameKey
				$key                      = $systemNodeNameKey + 'F5-NodeAddress' + $nodeAddressName
				$nodeAddressSessionStatus = $_.ltmNodeAddrSessionStatus
				$nodeAddressMonitorRule   = $_.ltmNodeAddrMonitorRule
				$nodeAddressEnabledState  = $_.ltmNodeAddrEnabledState								  

				if($_.ltmNodeAddrName) {
					$instance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']$")			
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressName$",$nodeAddressName)	
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressEnabledState$",$nodeAddressEnabledState)	
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressMonitorRule$",$nodeAddressMonitorRule)	
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressSessionStatus$",$nodeAddressSessionStatus)	
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/SystemNodeName$",$systemNodeNameKey)
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/Key$",$key)
					$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)
					$discoveryData.AddInstance($instance)
				}				
			} #EMD $discoveryFileContent.NodeAddrTable | ForEach-Object {}

		} elseif ($discoveryItem -eq 'TrafficGroup') {

			$discoveryFileContent.TrafficGroupStatusTable | ForEach-Object {						
				$groupDeviceName     = $_.sysCmTrafficGroupStatusDeviceName				
				$groupName           = $_.sysCmTrafficGroupStatusTrafficGroup
				
				$displayName         = 'F5-Traffic Group Item ' + $groupName + '-' + $groupDeviceName + ' On ' + $systemNodeNameKey  
				$key                 = $systemNodeNameKey + 'F5-TrafficGroupItem' + $groupName + $groupDeviceName		
				$key                 = $key.replace('/','').replace('-','')		
		
				$api.LogScriptEvent('ABC.F5.BIGIP DiscoveryF5Applications.ps1',402,2,"DiscoveryF5Applicaitons Found TrafficGroup key: $($key)")

				if ($_.sysCmTrafficGroupStatusDeviceName) {
					$instance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem']$")						
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem']/DeviceName$",$groupDeviceName)					
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem']/GroupName$",$groupName)	
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem']/SystemNodeName$",$systemNodeNameKey)	
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem']/Key$",$key)	
					$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)	
					$discoveryData.AddInstance($instance)
				}
			}

		} elseif ($discoveryItem -eq 'SyncStatus') {			

			$discoveryFileContent.SyncStatusDetails | ForEach-Object {						
				$syncStateItemPart = $_.sysCmSyncStatusDetailsDetails				
				$syncItemName      = $syncStateItemPart.Substring(0, $syncStateItemPart.IndexOf(' ')).replace(':','')				
				$displayName       = 'F5-SyncStatus Item ' + $syncItemName  + ' On ' + $systemNodeNameKey  
				$key               = $systemNodeNameKey + 'F5-SyncStatusItem' + $syncItemName									

				if ($_.sysCmSyncStatusDetailsDetails) {
					$instance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']$")						
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']/ItemName$",$syncItemName)									
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']/SystemNodeName$",$systemNodeNameKey)	
					$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']/Key$",$key)	
					$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)	
					$discoveryData.AddInstance($instance)
				}
			}

		} else {
  
			$FOO = 'Undefined type!'
  
		} #END if ($discoveryItem -eq 'PoolStatus') 

	} #END if ($f5HostUrl -ne '')  	

} #END foreach($f5HostItem in $F5BigIPHosts) 
	
$discoveryData