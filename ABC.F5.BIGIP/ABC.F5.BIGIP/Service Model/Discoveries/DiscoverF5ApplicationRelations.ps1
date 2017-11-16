param($sourceId,$managedEntityId,$discoveryItem)

$api           = New-Object -ComObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

$Global:Error.Clear()
$script:ErrorView      = 'NormalView'
$ErrorActionPreference = 'Continue'

$classF5MonServerRuntimeInfo               = Get-SCOMClass -Name 'ABC.F5.BIGIP.MonitoringServerRuntimeInfo'
$classF5MonServerRuntimeInfoInstance       = Get-SCOMClassInstance -Class $classF5MonServerRuntimeInfo
$classF5MonServerRuntimeInfoInstanceSingle = $classF5MonServerRuntimeInfoInstance | Select-Object -First 1

$tempPath              = $classF5MonServerRuntimeInfoInstanceSingle.'[ABC.F5.BIGIP.MonitoringServerRuntimeInfo].RemotePath'.Value

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
				
		$f5NodeName    = $f5HostName

		if ($discoveryItem -eq 'PoolStatus') {			

			
			$displayName   = 'F5-PoolStatusGroup' + ' On ' + $systemNodeNameKey
			$Key           = $systemNodeNameKey + 'F5-PoolStatusGroup' 
			$groupInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.PoolStatus.Group']$")
			$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus.Group']/Key$",$Key)
			$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus.Group']/SystemNodeName$",$systemNodeNameKey)	
			$groupInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)		

			$discoveryFileContent.PoolStatus | ForEach-Object {		  
				$poolName         = $_.ltmPoolStatusName
				$displayName      = 'F5-Pool ' + $poolName + ' On ' + $systemNodeNameKey
				$key              = $systemNodeNameKey + 'F5-Pool' + $poolName
				$poolEnabledState = $_.ltmPoolStatusEnabledState

				if ($_.ltmPoolStatusName) {
					$poolStatusInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']$")			
					$poolStatusInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/PoolStatusEnabledState$",$poolEnabledState)	
					$poolStatusInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/PoolStatusName$",$poolName)	
					$poolStatusInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/SystemNodeName$",$systemNodeNameKey)	
					$poolStatusInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/Key$",$key)
					$poolStatusInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)		
					
					$relInstance        = $discoveryData.CreateRelationshipInstance("$MPElement[Name='ABC.F5.BIGIP.PoolStatusGroupHostsPoolStatus']$")
					$relInstance.Source = $groupInstance
					$relInstance.Target = $poolStatusInstance
					$discoveryData.AddInstance($relInstance)

				}
			} #END $discoveryFileContent.PoolStatus | ForEach-Object {}

		} elseif ($discoveryItem -eq 'NodeAddrTable') {
			 
			$displayName   = 'F5-NodeAddressGroup' + ' On ' + $systemNodeNameKey 
			$Key           = $systemNodeNameKey + 'F5-NodeAddressGroup' 
			$groupInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.NodeAddress.Group']$")
			$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress.Group']/Key$",$Key)
			$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress.Group']/SystemNodeName$",$systemNodeNameKey)	
			$groupInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)					

			$discoveryFileContent.NodeAddrTable | ForEach-Object {				
				$nodeAddressName          = $_.ltmNodeAddrName
				$displayName              = 'F5-NodeAddress ' + $nodeAddressName + ' On ' + $systemNodeNameKey
				$key                      = $systemNodeNameKey + 'F5-NodeAddress' + $nodeAddressName
				$nodeAddressSessionStatus = $_.ltmNodeAddrSessionStatus
				$nodeAddressMonitorRule   = $_.ltmNodeAddrMonitorRule
				$nodeAddressEnabledState  = $_.ltmNodeAddrEnabledState								  

				if($_.ltmNodeAddrName) {
					$nodeAddressInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']$")			
					$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressName$",$nodeAddressName)	
					$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressEnabledState$",$nodeAddressEnabledState)	
					$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressMonitorRule$",$nodeAddressMonitorRule)	
					$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressSessionStatus$",$nodeAddressSessionStatus)	
					$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/SystemNodeName$",$systemNodeNameKey)
					$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/Key$",$key)
					$nodeAddressInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)
					
					$relInstance        = $discoveryData.CreateRelationshipInstance("$MPElement[Name='ABC.F5.BIGIP.NodeAddressGroupHostsNodeAddress']$")
					$relInstance.Source = $groupInstance
					$relInstance.Target = $nodeAddressInstance
					$discoveryData.AddInstance($relInstance)

				}				
			} #EMD $discoveryFileContent.NodeAddrTable | ForEach-Object {}

		} elseif ($discoveryItem -eq 'TrafficGroup') {	
			
			$groupNames = @()
			$discoveryFileContent.TrafficGroupStatusTable | ForEach-Object {						
				$groupNames += $_.sysCmTrafficGroupStatusTrafficGroup
			}
			$groupNames = $groupNames | Sort-Object -Unique		  
						
			foreach($groupName in $groupNames) {	
				
				$displayName   = 'F5-TrafficGroupItemGroup' + '-' +  $groupName + ' On ' + $systemNodeNameKey 
				$Key           = $systemNodeNameKey + 'F5-TrafficGroupItemGroup' + $groupName
				$f5GroupName   = 'F5-TrafficGroupItemGroup' + '-' +  $groupName + '-' + $systemNodeNameKey 				  
			
				$groupInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']$")
				$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']/Key$",$Key)
				$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']/GroupName$",$f5GroupName)
				$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']/SystemNodeName$",$systemNodeNameKey)	
				$groupInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)		
	  
				$discoveryFileContent.TrafficGroupStatusTable | ForEach-Object {	
										
					$instGroupDeviceName = $_.sysCmTrafficGroupStatusDeviceName				
					$instGroupName       = $_.sysCmTrafficGroupStatusTrafficGroup
					$instSystemNodeName  = $systemNodeNameKey
				
					$instDisplayName     = 'F5-Traffic Group Item ' + $instGroupName + '-' + $instGroupDeviceName + ' On ' + $instSystemNodeName  
					$instKey             = $instSystemNodeName + 'F5-TrafficGroupItem' + $instGroupName + $instGroupDeviceName		
					$instKey             = $instKey.replace('/','').replace('-','')						
			
					if ($_.sysCmTrafficGroupStatusDeviceName) {					

						$itemInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem']$")						
						$itemInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem']/DeviceName$",$instGroupDeviceName)					
						$itemInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem']/GroupName$",$instGroupName)	
						$itemInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem']/SystemNodeName$",$instSystemNodeName)	
						$itemInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem']/Key$",$instKey)	
						$itemInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $instDisplayName)		
			
						$relInstance        = $discoveryData.CreateRelationshipInstance("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItemGroupHostsTrafficGroupItem']$")
						$relInstance.Source = $groupInstance
						$relInstance.Target = $itemInstance
						$discoveryData.AddInstance($relInstance)

					}
		  
				} #END $discoveryFileContent.TrafficGroupStatusTable | ForEach-Object {}
	  
			} #END foreach($groupName in $groupNames)      

		} elseif ($discoveryItem -eq 'SyncStatus') {			

			$displayName   = 'F5-SyncStatusItemGroup' + ' On ' + $systemNodeNameKey 
			$Key           = $systemNodeNameKey + 'F5-SyncStatusItemGroup'
			$f5GroupName   = 'F5-SyncStatusItemGroup' + '-' + $systemNodeNameKey 

			$groupInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']$")
			$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']/Key$",$Key)
			$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']/GroupName$",$f5GroupName)
			$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']/SystemNodeName$",$systemNodeNameKey)	
			$groupInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)							

			$discoveryFileContent.SyncStatusDetails | ForEach-Object {						
				$syncStateItemPart = $_.sysCmSyncStatusDetailsDetails				
				$syncItemName      = $syncStateItemPart.Substring(0, $syncStateItemPart.IndexOf(' ')).replace(':','')				
				$displayName       = 'F5-SyncStatus Item ' + $syncItemName  + ' On ' + $systemNodeNameKey  
				$key               = $systemNodeNameKey + 'F5-SyncStatusItem' + $syncItemName									

				if ($_.sysCmSyncStatusDetailsDetails) {
					$itemInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']$")						
					$itemInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']/ItemName$",$syncItemName)									
					$itemInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']/SystemNodeName$",$systemNodeNameKey)	
					$itemInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']/Key$",$key)	
					$itemInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)	
					
					$relInstance        = $discoveryData.CreateRelationshipInstance("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItemGroupHostsSyncStatusItem']$")
					$relInstance.Source = $groupInstance
					$relInstance.Target = $itemInstance
					$discoveryData.AddInstance($relInstance)
				}

			} #END $discoveryFileContent.SyncStatusDetails | ForEach-Object {}

		} else {
  
			$FOO = 'Undefined type!'
  
		} #END if ($discoveryItem -eq 'PoolStatus') 

	} #END if ($f5HostUrl -ne '')  	

} #END foreach($f5HostItem in $F5BigIPHosts) 
	
$discoveryData