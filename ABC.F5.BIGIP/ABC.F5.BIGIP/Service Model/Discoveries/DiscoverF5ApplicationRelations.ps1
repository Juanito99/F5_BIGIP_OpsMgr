param($sourceId,$managedEntityId,$groupItem)

$api                    = New-Object -ComObject 'MOM.ScriptAPI'
$discoveryData          = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

$classF5System          = Get-SCOMClass -Name 'ABC.F5.BIGIP.System'
$classF5SystemInstances = Get-SCOMClassInstance -Class $classF5System
$f5NodeNames            = $classF5SystemInstances.'[ABC.F5.BIGIP.System].SystemNodeName'.Value


if ($groupItem -eq 'PoolStatusGroup') {

	$classF5PoolStatus          = Get-SCOMClass -Name 'ABC.F5.BIGIP.PoolStatus'
	$classF5PoolStatusInstances = Get-SCOMClassInstance -Class $classF5PoolStatus

	foreach ($f5NodeName in $f5NodeNames) {

		$displayName   = 'F5-PoolStatusGroup' + ' On ' + $f5NodeName
		$Key           = $f5NodeName + 'F5-PoolStatusGroup' 
		$groupInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.PoolStatus.Group']$")
		$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus.Group']/Key$",$Key)
		$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus.Group']/SystemNodeName$",$f5NodeName)	
		$groupInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)		

		$classF5PoolStatusInstances | Where-Object {$_.'[ABC.F5.BIGIP.PoolStatus].SystemNodeName'.Value -eq $f5NodeName} | ForEach-Object {
  
			$poolStatusInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']$")
			$poolStatusInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/PoolStatusEnabledState$",$_.'[ABC.F5.BIGIP.PoolStatus].PoolStatusEnabledState'.Value)	
			$poolStatusInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/PoolStatusName$",$_.'[ABC.F5.BIGIP.PoolStatus].PoolStatusName'.Value)	
			$poolStatusInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/SystemNodeName$",$_.'[ABC.F5.BIGIP.PoolStatus].SystemNodeName'.Value)	
			$poolStatusInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus']/Key$",$_.'[ABC.F5.BIGIP.PoolStatus].Key'.Value)
			$poolStatusInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $_.'[System.Entity].DisplayName'.Value)		
  
			$relInstance        = $discoveryData.CreateRelationshipInstance("$MPElement[Name='ABC.F5.BIGIP.PoolStatusGroupHostsPoolStatus']$")
			$relInstance.Source = $groupInstance
			$relInstance.Target = $poolStatusInstance
			$discoveryData.AddInstance($relInstance)
  
		} #END $classF5SystemInstances | Where-Object {$_.'[ABC.F5.BIGIP.PoolStatus].SystemNodeName'.Value -eq $f5NodeName} | ForEach-Object  

	} #END foreach ($f5NodeName in $f5NodeNames)

} elseif ($groupItem -eq 'NodeAddressGroup') {
		
	$classF5NodeAddress          = Get-SCOMClass -Name 'ABC.F5.BIGIP.NodeAddress'
	$classF5NodeAddressInstances = Get-SCOMClassInstance -Class $classF5NodeAddress	

	foreach ($f5NodeName in $f5NodeNames) {

		$displayName   = 'F5-NodeAddressGroup' + ' On ' + $f5NodeName 
		$Key           = $f5NodeName + 'F5-NodeAddressGroup' 
		$groupInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.NodeAddress.Group']$")
		$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress.Group']/Key$",$Key)
		$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress.Group']/SystemNodeName$",$f5NodeName)	
		$groupInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)					

		$classF5NodeAddressInstances | Where-Object {$_.'[ABC.F5.BIGIP.NodeAddress].SystemNodeName'.Value -eq $f5NodeName} | ForEach-Object {  
						
			$nodeAddressName          = $_.'[ABC.F5.BIGIP.NodeAddress].NodeAddressName'.Value
			$displayName              = $f5NodeName + 'F5-NodeAddress' + $nodeAddressName			
			$key                      = $displayName
			
			$nodeAddressInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']$")			
			$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressName$",$_.'[ABC.F5.BIGIP.NodeAddress].NodeAddressName'.Value)	
			$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressEnabledState$",$_.'[ABC.F5.BIGIP.NodeAddress].NodeAddressEnabledState'.Value)	
			$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressMonitorRule$",$_.'[ABC.F5.BIGIP.NodeAddress].NodeAddressMonitorRule'.Value)	
			$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/NodeAddressSessionStatus$",$_.'[ABC.F5.BIGIP.NodeAddress].NodeAddressSessionStatus'.Value)	
			$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/SystemNodeName$",$f5NodeName)
			$nodeAddressInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress']/Key$",$key)
			$nodeAddressInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $_.'[System.Entity].DisplayName'.Value)		
			
			$relInstance        = $discoveryData.CreateRelationshipInstance("$MPElement[Name='ABC.F5.BIGIP.NodeAddressGroupHostsNodeAddress']$")
			$relInstance.Source = $groupInstance
			$relInstance.Target = $nodeAddressInstance
			$discoveryData.AddInstance($relInstance)
  
		} #END $classF5NodeAddressInstances | Where-Object {$_.'[ABC.F5.BIGIP.NodeAddress].SystemNodeName'.Value -eq $f5NodeName} | ForEach-Object  

	} #END foreach ($f5NodeName in $f5NodeNames)

} elseif ($groupItem -eq 'TrafficGroupInstancesGroup') {
		
	$classF5TrafficGroupItem          = Get-SCOMClass -Name 'ABC.F5.BIGIP.TrafficGroupItem'
	$classF5TrafficGroupItemInstances = Get-SCOMClassInstance -Class $classF5TrafficGroupItem		

	foreach ($f5NodeName in $f5NodeNames) {		
		
		$groups     = $classF5TrafficGroupItemInstances | Where-Object { $_.'[ABC.F5.BIGIP.TrafficGroupItem].SystemNodeName'.Value -eq $f5NodeName } 
		$groupNames = $groups                           | ForEach-Object { $_.'[ABC.F5.BIGIP.TrafficGroupItem].GroupName'.Value }
		$groupNames = $groupNames                       | Sort-Object -Unique		

		foreach($groupName in $groupNames) {
						
			$displayName   = 'F5-TrafficGroupItemGroup' + '-' +  $groupName + ' On ' + $f5NodeName 
			$Key           = $f5NodeName + 'F5-TrafficGroupItemGroup' + $groupName
			$f5GroupName   = 'F5-TrafficGroupItemGroup' + '-' +  $groupName + '-' + $f5NodeName 		

			$groupInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']$")
			$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']/Key$",$Key)
			$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']/GroupName$",$f5GroupName)
			$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']/SystemNodeName$",$f5NodeName)	
			$groupInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)		
			
			$classF5TrafficGroupItemInstances | Where-Object { ($_.'[ABC.F5.BIGIP.TrafficGroupItem].GroupName'.Value -eq $groupName) -and ($_.'[ABC.F5.BIGIP.TrafficGroupItem].SystemNodeName'.Value -eq $f5NodeName) } | ForEach-Object {  					
				
				$instGroupDeviceName = $_.'[ABC.F5.BIGIP.TrafficGroupItem].DeviceName'.Value
				$instGroupName       = $_.'[ABC.F5.BIGIP.TrafficGroupItem].GroupName'.Value
				$instSystemNodeName  = $_.'[ABC.F5.BIGIP.TrafficGroupItem].SystemNodeName'.Value

				$instDisplayName     = 'F5-Traffic Group Item ' + $instGroupName + '-' + $instGroupDeviceName + ' On ' + $instSystemNodeName  
				$instKey             = $instSystemNodeName + 'F5-TrafficGroupItem' + $instGroupName + $instGroupDeviceName		
				$instKey             = $instKey.replace('/','').replace('-','')		
				
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
  
			} #END $classF5NodeAddressInstances | Where-Object {$_.'[ABC.F5.BIGIP.NodeAddress].SystemNodeName'.Value -eq $f5NodeName} | ForEach-Object  

		} #END foreach($groupName in $groupNames)				

	} #END foreach ($f5NodeName in $f5NodeNames)

} elseif ($groupItem -eq 'SyncStatusItemGroup') {		
		
	$classF5SyncStatusItem          = Get-SCOMClass -Name 'ABC.F5.BIGIP.SyncStatusItem'
	$classF5SyncStatusItemInstances = Get-SCOMClassInstance -Class $classF5SyncStatusItem	

	foreach ($f5NodeName in $f5NodeNames) {				
	
		$displayName   = 'F5-SyncStatusItemGroup' + ' On ' + $f5NodeName 
		$Key           = $f5NodeName + 'F5-SyncStatusItemGroup'
		$f5GroupName   = 'F5-SyncStatusItemGroup' + '-' + $f5NodeName 

		$groupInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']$")
		$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']/Key$",$Key)
		$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']/GroupName$",$f5GroupName)
		$groupInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']/SystemNodeName$",$f5NodeName)	
		$groupInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)							
						
		$classF5SyncStatusItemInstances | Where-Object { $_.'[ABC.F5.BIGIP.SyncStatusItem].SystemNodeName'.Value -eq $f5NodeName } | ForEach-Object {  					
				
			$instKey            = $_.'[ABC.F5.BIGIP.SyncStatusItem].Key'.Value
			$instItemName       = $_.'[ABC.F5.BIGIP.SyncStatusItem].ItemName'.Value
			$instSystemNodeName = $_.'[ABC.F5.BIGIP.SyncStatusItem].SystemNodeName'.Value
			$instDisplayName    = 'F5-SyncStatus Item ' + $syncItemName  + ' On ' + $instSystemNodeName  				
			
			$itemInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']$")										
			$itemInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']/ItemName$",$instItemName)	
			$itemInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']/SystemNodeName$",$instSystemNodeName)	
			$itemInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem']/Key$",$instKey)	
			$itemInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $instDisplayName)		
			
			$relInstance        = $discoveryData.CreateRelationshipInstance("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItemGroupHostsSyncStatusItem']$")
			$relInstance.Source = $groupInstance
			$relInstance.Target = $itemInstance
			$discoveryData.AddInstance($relInstance)
  
		} #END $classF5NodeAddressInstances | Where-Object {$_.'[ABC.F5.BIGIP.NodeAddress].SystemNodeName'.Value -eq $f5NodeName} | ForEach-Object  			

	} #END foreach ($f5NodeName in $f5NodeNames)

} elseif ($groupItem -eq 'SystemHostsPoolStatusGroup') {

	$classF5PoolStatusGroup          = Get-SCOMClass -Name 'ABC.F5.BIGIP.PoolStatus.Group'
	$classF5PoolStatusGroupInstances = Get-SCOMClassInstance -Class $classF5PoolStatusGroup
	
	$classF5SystemInstances | ForEach-Object {	
	
		$classF5SystemInstance = $_
		$f5SystemNodeName      = $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemNodeName'.Value
			 
		$srcInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.System']$")
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemNodeName$", $f5SystemNodeName)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemRelease$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemRelease'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemName$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemName'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductDate$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductDate'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductBuild$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductBuild'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductName$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductName'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductVersion$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductVersion'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/IPAddress$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].IPAddress'.Value)
		$discoveryData.AddInstance($srcInstance)	

		$classF5PoolStatusGroupInstances | Where-Object {$_.'[ABC.F5.BIGIP.PoolStatus.Group].SystemNodeName'.Value -eq $f5SystemNodeName} | ForEach-Object {
			
			$classF5PoolStatusGroupInstance = $_

			$displayName    = 'F5-PoolStatusGroup' + ' On ' + $f5SystemNodeName
			$Key            = $f5SystemNodeName + 'F5-PoolStatusGroup' 
			$targetInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.PoolStatus.Group']$")
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus.Group']/Key$",$Key)
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.PoolStatus.Group']/SystemNodeName$",$f5SystemNodeName)	
			$targetInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)	
			$discoveryData.AddInstance($targetInstance)
			
			$relInstance = $discoveryData.CreateRelationShipInstance("$MPElement[Name='ABC.F5.BIGIP.SystemHostsPoolStatusGroup']$")
			$relInstance.Source = $srcInstance
			$relInstance.Target = $targetInstance									
			$discoveryData.AddInstance($relInstance)

		} #END $classF5PoolStatusGroupInstances | Where-Object {$_.'[ABC.F5.BIGIP.PoolStatus.Group].SystemNodeName'.Value -eq $f5SystemNodeName} | ForEach-Object 

	} #END $classF5SystemInstances | ForEach-Object 

} elseif ($groupItem -eq 'SystemHostsNodeAddressGroup')	{

	$classF5NodeAddressGroup          = Get-SCOMClass -Name 'ABC.F5.BIGIP.NodeAddress.Group'
	$classF5NodeAddressGroupInstances = Get-SCOMClassInstance -Class $classF5NodeAddressGroup
	
	$classF5SystemInstances | ForEach-Object {	
	
		$classF5SystemInstance = $_
		$f5SystemNodeName      = $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemNodeName'.Value
			
		$srcInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.System']$")
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemNodeName$", $f5SystemNodeName)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemRelease$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemRelease'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemName$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemName'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductDate$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductDate'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductBuild$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductBuild'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductName$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductName'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductVersion$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductVersion'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/IPAddress$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].IPAddress'.Value)
		$discoveryData.AddInstance($srcInstance)	

		$classF5NodeAddressGroupInstances | Where-Object {$_.'[ABC.F5.BIGIP.NodeAddress.Group].SystemNodeName'.Value -eq $f5SystemNodeName} | ForEach-Object {
			
			$classF5PoolStatusGroupInstance = $_	

			$displayName    = 'F5-NodeAddressGroup' + ' On ' + $f5SystemNodeName
			$Key            = $f5SystemNodeName + 'F5-NodeAddressGroup' 
			$targetInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.NodeAddress.Group']$")
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress.Group']/Key$",$Key)
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.NodeAddress.Group']/SystemNodeName$",$f5SystemNodeName)	
			$targetInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)	
			$discoveryData.AddInstance($targetInstance)
			
			$relInstance        = $discoveryData.CreateRelationShipInstance("$MPElement[Name='ABC.F5.BIGIP.SystemHostsNodeAddressGroup']$")
			$relInstance.Source = $srcInstance
			$relInstance.Target = $targetInstance									
			$discoveryData.AddInstance($relInstance)

		} #END $classF5NodeAddressGroupInstances | Where-Object {$_.'[ABC.F5.BIGIP.PoolStatus.Group].SystemNodeName'.Value -eq $f5SystemNodeName} | ForEach-Object 

	} #END $classF5SystemInstances | ForEach-Object 

} elseif ($groupItem -eq 'SystemHostsTrafficGroupItemGroup')	{
	
	$classF5TrafficItemGroup          = Get-SCOMClass -Name 'ABC.F5.BIGIP.TrafficGroupItem.Group'
	$classF5TrafficItemGroupInstances = Get-SCOMClassInstance -Class $classF5TrafficItemGroup
	
	$classF5SystemInstances | ForEach-Object {	
	
		$classF5SystemInstance = $_
		$f5SystemNodeName      = $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemNodeName'.Value		
	
		$srcInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.System']$")
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemNodeName$", $f5SystemNodeName)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemRelease$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemRelease'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemName$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemName'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductDate$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductDate'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductBuild$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductBuild'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductName$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductName'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductVersion$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductVersion'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/IPAddress$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].IPAddress'.Value)
		$discoveryData.AddInstance($srcInstance)	

		$classF5TrafficItemGroupInstances | Where-Object {$_.'[ABC.F5.BIGIP.TrafficGroupItem.Group].SystemNodeName'.Value -eq $f5SystemNodeName} | ForEach-Object {
			
			$classF5TrafficItemGroupInstance = $_		
						
			$displayName   = $classF5TrafficItemGroupInstance.DisplayName
			$Key           = $classF5TrafficItemGroupInstance.'[ABC.F5.BIGIP.TrafficGroupItem.Group].Key'.Value
			$f5GroupName   = $classF5TrafficItemGroupInstance.'[ABC.F5.BIGIP.TrafficGroupItem.Group].GroupName'.Value

			$targetInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']$")
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']/Key$",$Key)
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']/GroupName$",$f5GroupName)
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.TrafficGroupItem.Group']/SystemNodeName$",$f5SystemNodeName)	
			$targetInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)		
			
			$relInstance        = $discoveryData.CreateRelationShipInstance("$MPElement[Name='ABC.F5.BIGIP.SystemHostsTrafficGroupItemGroup']$")
			$relInstance.Source = $srcInstance
			$relInstance.Target = $targetInstance									
			$discoveryData.AddInstance($relInstance)

		} #END $classF5NodeAddressGroupInstances | Where-Object {$_.'[ABC.F5.BIGIP.PoolStatus.Group].SystemNodeName'.Value -eq $f5SystemNodeName} | ForEach-Object 

	} #END $classF5SystemInstances | ForEach-Object 


} elseif ($groupItem -eq 'SystemHostsSyncStatusItemGroup')	{
	
	$classF5SyncStatusItemGroup          = Get-SCOMClass -Name 'ABC.F5.BIGIP.SyncStatusItem.Group'
	$classF5SyncStatusItemGroupInstances = Get-SCOMClassInstance -Class $classF5SyncStatusItemGroup
	
	$classF5SystemInstances | ForEach-Object {	
	
		$classF5SystemInstance = $_
		$f5SystemNodeName      = $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemNodeName'.Value		
	
		$srcInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.System']$")
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemNodeName$", $f5SystemNodeName)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemRelease$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemRelease'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemName$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemName'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductDate$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductDate'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductBuild$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductBuild'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductName$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductName'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductVersion$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].ProductVersion'.Value)
		$srcInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/IPAddress$", $classF5SystemInstance.'[ABC.F5.BIGIP.System].IPAddress'.Value)
		$discoveryData.AddInstance($srcInstance)	

		$classF5SyncStatusItemGroupInstances | Where-Object {$_.'[ABC.F5.BIGIP.SyncStatusItem.Group].SystemNodeName'.Value -eq $f5SystemNodeName} | ForEach-Object {
			
			$classF5SyncStatusItemGroupInstance = $_		
						
			$displayName   = $classF5SyncStatusItemGroupInstance.DisplayName
			$Key           = $classF5SyncStatusItemGroupInstance.'[ABC.F5.BIGIP.SyncStatusItem.Group].Key'.Value
			$f5GroupName   = $classF5SyncStatusItemGroupInstance.'[ABC.F5.BIGIP.SyncStatusItem.Group].GroupName'.Value

			$targetInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']$")
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']/Key$",$Key)
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']/GroupName$",$f5GroupName)
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.SyncStatusItem.Group']/SystemNodeName$",$f5SystemNodeName)	
			$targetInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)		
			
			$relInstance        = $discoveryData.CreateRelationShipInstance("$MPElement[Name='ABC.F5.BIGIP.SystemHostsSyncStatusItemGroup']$")
			$relInstance.Source = $srcInstance
			$relInstance.Target = $targetInstance									
			$discoveryData.AddInstance($relInstance)

		} #END $classF5NodeAddressGroupInstances | Where-Object {$_.'[ABC.F5.BIGIP.PoolStatus.Group].SystemNodeName'.Value -eq $f5SystemNodeName} | ForEach-Object 

	} #END $classF5SystemInstances | ForEach-Object 

} else {

	$foo = 'Undefined discovery type'

}


$discoveryData