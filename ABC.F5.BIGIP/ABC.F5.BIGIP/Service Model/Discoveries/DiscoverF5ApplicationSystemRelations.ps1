param($sourceId,$managedEntityId,$groupItem)

$api                    = New-Object -ComObject 'MOM.ScriptAPI'
$discoveryData          = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

$classF5System          = Get-SCOMClass -Name 'ABC.F5.BIGIP.System'
$classF5SystemInstances = Get-SCOMClassInstance -Class $classF5System

$f5NodeNames            = $classF5SystemInstances.'[ABC.F5.BIGIP.System].SystemNodeName'.Value

$api.LogScriptEvent('ABC.F5.BIGIP DiscoverF5ApplicationSystemRelations.ps1',4000,4,"DiscoverF5ApplicationSystemRelations start with groupItem : $($groupItem)")


if ($groupItem -eq 'SystemHostsPoolStatusGroup') {

	$classF5PoolStatusGroup          = Get-SCOMClass -Name 'ABC.F5.BIGIP.PoolStatus.Group'
	$classF5PoolStatusGroupInstances = Get-SCOMClassInstance -Class $classF5PoolStatusGroup

	$api.LogScriptEvent('ABC.F5.BIGIP DiscoverF5ApplicationSystemRelations.ps1',4000,2,"DiscoverF5ApplicationSystemRelations classF5PoolStatusGroupInstances Count : $($classF5PoolStatusGroupInstances.count)")

	$classF5SystemInstances | ForEach-Object {

		$classF5SystemInstance = $_
		$f5SystemNodeName      = $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemNodeName'.Value
		$api.LogScriptEvent('ABC.F5.BIGIP DiscoverF5ApplicationSystemRelations.ps1',4001,2,"DiscoverF5ApplicationSystemRelations f5NodeName : $($f5SystemNodeName)")

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

		$noClassF5PoolStatusGroupInstances = ($classF5PoolStatusGroupInstances | Where-Object {$_.'[ABC.F5.BIGIP.PoolStatus.Group].SystemNodeName'.Value -eq $f5SystemNodeName}).count
		$api.LogScriptEvent('ABC.F5.BIGIP DiscoverF5ApplicationSystemRelations.ps1',4001,1,"DiscoverF5ApplicationSystemRelations f5NodeName Match noClassF5PoolStatusGroupInstances : $($noClassF5PoolStatusGroupInstances)")

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

	$api.LogScriptEvent('ABC.F5.BIGIP DiscoverF5ApplicationSystemRelations.ps1',4000,2,"DiscoverF5ApplicationSystemRelations classF5NodeAddressGroupInstances Count : $($classF5NodeAddressGroupInstances.count)")

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

	$api.LogScriptEvent('ABC.F5.BIGIP DiscoverF5ApplicationSystemRelations.ps1',4000,2,"DiscoverF5ApplicationSystemRelations classF5TrafficItemGroupInstances Count : $($classF5TrafficItemGroupInstances.count)")

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

	$api.LogScriptEvent('ABC.F5.BIGIP DiscoverF5ApplicationSystemRelations.ps1',4000,2,"DiscoverF5ApplicationSystemRelations classF5SyncStatusItemGroupInstances Count : $($classF5SyncStatusItemGroupInstances.count)")

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

	$api.LogScriptEvent('ABC.F5.BIGIP DiscoverF5ApplicationSystemRelations.ps1',4000,1,"DiscoverF5ApplicationSystemRelations error in discovery $($error)")

}

$discoveryData