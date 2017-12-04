param($sourceId,$managedEntityId,$tempPath)


$classF5MonServerRuntimeInfo = Get-SCOMClass -Name 'ABC.F5.BIGIP.MonitoringServerRuntimeInfo'
$classF5MonServerRuntimeInfoInstance = Get-SCOMClassInstance -Class $classF5MonServerRuntimeInfo
$tempPath = $classF5MonServerRuntimeInfoInstance.'[ABC.F5.BIGIP.MonitoringServerRuntimeInfo].RemotePath'.Value


$api           = New-Object -ComObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0,$sourceId,$managedEntityId)

$classF5System                    = Get-SCOMClass -Name 'ABC.F5.BIGIP.System'
$classF5SystemInstances           = Get-SCOMClassInstance -Class $classF5System

$classF5CPU                       = Get-SCOMClass -Name 'ABC.F5.BIGIP.CPU'
$classF5CPUInstances              = Get-SCOMClassInstance -Class $classF5CPU

$classF5Memory                    = Get-SCOMClass -Name 'ABC.F5.BIGIP.Memory'
$classF5MemoryInstances           = Get-SCOMClassInstance -Class $classF5Memory

$classF5Disk                      = Get-SCOMClass -Name 'ABC.F5.BIGIP.Disk'
$classF5DiskInstances             = Get-SCOMClassInstance -Class $classF5Disk


$classF5SystemInstances | ForEach-Object {	
	
	$classF5SystemInstance = $_

	if ($classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemNodeName'.value -eq '') {

		$foo = 'bar'

	} else {

		$f5SystemNodeName = $classF5SystemInstance.'[ABC.F5.BIGIP.System].SystemNodeName'.Value
			
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
		
		$classF5CPUInstances | Where-Object {$_.'[ABC.F5.BIGIP.CPU].SystemNodeName'.Value -eq $f5SystemNodeName} | ForEach-Object {						

			[string]$cpuID = [string]$($_.'[ABC.F5.BIGIP.CPU].Id'.Value)
			[string]$key   = [string]$($_.'[ABC.F5.BIGIP.CPU].Key'.Value) 			

			$targetInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.CPU']$")
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.CPU']/Id$", $cpuID)
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.CPU']/Key$", $key)
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.CPU']/SystemNodeName$", $f5SystemNodeName)			
			$discoveryData.AddInstance($targetInstance)
			
			$relInstance        = $discoveryData.CreateRelationShipInstance("$MPElement[Name='ABC.F5.BIGIP.SystemHostsCPU']$")
			$relInstance.Source = $srcInstance
			$relInstance.Target = $targetInstance									
			$discoveryData.AddInstance($relInstance)

		}

		$classF5DiskInstances | Where-Object {$_.'[ABC.F5.BIGIP.Disk].SystemNodeName'.Value -eq $f5SystemNodeName} | ForEach-Object {						

			[string]$totalSize = [string]$($_.'[ABC.F5.BIGIP.Disk].TotalSize'.Value) 	
			[string]$key       = [string]$($_.'[ABC.F5.BIGIP.Disk].Key'.Value) 	
			
			$targetInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.Disk']$")
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Disk']/TotalSize$", $totalSize)
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Disk']/FullPathAttr$", $_.'[ABC.F5.BIGIP.Disk].FullPathAttr'.Value)
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Disk']/Key$", $key)
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Disk']/SystemNodeName$", $f5SystemNodeName)			
			$discoveryData.AddInstance($targetInstance)

			$relInstance        = $discoveryData.CreateRelationShipInstance("$MPElement[Name='ABC.F5.BIGIP.SystemHostsDisk']$")
			$relInstance.Source = $srcInstance
			$relInstance.Target = $targetInstance									
			$discoveryData.AddInstance($relInstance)

		}		

		$classF5MemoryInstances | Where-Object {$_.'[ABC.F5.BIGIP.Memory].SystemNodeName'.Value -eq $f5SystemNodeName} | ForEach-Object {						

			[string]$memoryTotal = [string]$($_.'[ABC.F5.BIGIP.Memory].MemoryTotal'.Value) 	
			[string]$key         = [string]$($_.'[ABC.F5.BIGIP.Memory].Key'.Value) 
			
			$targetInstance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.Memory']$")
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Memory']/MemoryTotal$", $memoryTotal)			
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Memory']/Key$", $key)			
			$targetInstance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Memory']/SystemNodeName$", $f5SystemNodeName)			
			$discoveryData.AddInstance($targetInstance)

			$relInstance        = $discoveryData.CreateRelationShipInstance("$MPElement[Name='ABC.F5.BIGIP.SystemHostsMemory']$")
			$relInstance.Source = $srcInstance
			$relInstance.Target = $targetInstance									
			$discoveryData.AddInstance($relInstance)

		}
	
	}
	
}

$discoveryData