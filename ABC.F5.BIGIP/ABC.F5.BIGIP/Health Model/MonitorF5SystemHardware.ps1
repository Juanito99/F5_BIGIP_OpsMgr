param($MonitorItem, $Threshold)

$api = New-Object -ComObject 'MOM.ScriptAPI'

$Global:Error.Clear()
$script:ErrorView      = 'NormalView'
$ErrorActionPreference = 'Continue'

$classF5MonServerRuntimeInfo               = Get-SCOMClass -Name 'ABC.F5.BIGIP.MonitoringServerRuntimeInfo'
$classF5MonServerRuntimeInfoInstance       = Get-SCOMClassInstance -Class $classF5MonServerRuntimeInfo
$classF5MonServerRuntimeInfoInstanceSingle = $classF5MonServerRuntimeInfoInstance | Select-Object -First 1

$tempPath       = $classF5MonServerRuntimeInfoInstanceSingle.'[ABC.F5.BIGIP.MonitoringServerRuntimeInfo].RemotePath'.Value
$testedAt       = "Tested on: $(Get-Date -Format u) / $(([TimeZoneInfo]::Local).DisplayName)"

$F5BigIPHosts   = Import-Csv -Path $($tempPath + '\' + 'F5-BigIP-Hosts.csv')
$discoveryFiles = Get-ChildItem -Path $tempPath -Filter '*F5-Discovery-*.json' | Select-Object -ExpandProperty Name

 
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
			$discoveryFile = $discoveryFiles | Where-Object { ($_ -match $MonitorItem) -and ($_ -match $f5HostUrl)}
			foreach($dFile in $discoveryFile) {
				$discoveryFileContent += Get-Content -Path $($tempPath + '\' + $dFile) | ConvertFrom-Json
			}  
		} else {
			$discoveryFile        = $discoveryFiles | Where-Object { ($_ -match $MonitorItem) -and ($_ -match $f5HostUrl)}
			$discoveryFileContent = Get-Content -Path $($tempPath + '\' + $discoveryFile) | ConvertFrom-Json
		}

		$discoverySystemFile        = $discoveryFiles | Where-Object {($_ -match 'GeneralInfo') -and ($_ -match $f5HostUrl)}
		$discoverySystemFileContent = Get-Content -Path $($tempPath + '\' + $discoverySystemFile) | ConvertFrom-Json
		$systemNodeNameKey          = $($discoverySystemFileContent.GeneralInfo.SystemNodeName)
				
		if ($MonitorItem -eq 'CPU') {	

			$classF5CPU          = Get-SCOMClass -Name 'ABC.F5.BIGIP.CPU'
			$classF5CPUInstances = Get-SCOMClassInstance -Class $classF5CPU
	
			$classF5CPUInstances | Where-Object {$_.'[ABC.F5.BIGIP.CPU].SystemNodeName'.Value -eq $systemNodeNameKey} | ForEach-Object {						

				$f5CPU = $_

				[string]$cpuID = [string]$($f5CPU.'[ABC.F5.BIGIP.CPU].Id'.Value)
				[string]$key   = [string]$($f5CPU.'[ABC.F5.BIGIP.CPU].Key'.Value) 			
	
				$discoveryFileContent.F5CPU | Where-Object {$_.CPUId -eq $cpuID} | ForEach-Object {		  
					$cpuID   = $($_.CPUId).ToString()				
					$cpuIdle = $_.Idle
					$rawInfo = "Idle: $($_.Idle) User: $($_.User) System: $($_.System)"
					[int]$Threshold			

					$key = $systemNodeNameKey + 'F5-CPU' + $cpuID 			

					if (($Threshold -gt 50) -and ($Threshold -lt 99)) { 
						$cpuMaxThreshold = 100 - $Threshold  
						[int]$cpuIdle = [Math]::Abs($_.Idle)
						if ($cpuIdle -lt $cpuMaxThreshold) {
							$state       = 'Failure'
							$supplement  = "Threshold reached of: $Threshold from max: $cpuMaxThreshold"
							$supplement += "`n Idle: $($cpuIdle) " 
						} else {
							$state      = 'Success'
							$supplement = "Result within threshold of: $Threshold from max: $cpuMaxThreshold"
							$supplement += "`n Idle: $($cpuIdle) " 
						}      
					} else {
						[int]$cpuMaxThreshold = 90
						if ($cpuIdle -lt $cpuMaxThreshold) {
							$state      = 'Failure'
							$supplement = "Threshold reached of: $Threshold from default max: $cpuMaxThreshold"
						} else {
							$state      = 'Success'
							$supplement = "Result within threshold of: $Threshold default from max: $cpuMaxThreshold"
						}
					}			

					$raw = "CPUId: $($cpuID); Key: $($key); State: $($state); Supplement: $($supplement); testedAt: $($testedAt)"					

					$bag = $api.CreatePropertybag()					
					$bag.AddValue("cpuID",$cpuID)
					$bag.AddValue("Key",$key)		
					$bag.AddValue("State",$state)				
					$bag.AddValue("Supplement",$supplement)		
					$bag.AddValue("TestedAt",$testedAt)			
					$bag

				} 
		
			} 

		} elseif ($MonitorItem -eq 'Disks') {	

			$classF5Disk          = Get-SCOMClass -Name 'ABC.F5.BIGIP.Disk'
			$classF5DiskInstances = Get-SCOMClassInstance -Class $classF5Disk
	
			$classF5DiskInstances | Where-Object {$_.'[ABC.F5.BIGIP.Disk].SystemNodeName'.Value -eq $systemNodeNameKey} | ForEach-Object {						

				$f5Disk                     = $_				
				[string]$key                = [string]$($f5Disk.'[ABC.F5.BIGIP.Disk].Key'.Value) 	
				[string]$f5DiskFullPathAttr = [string]$($f5Disk.'[ABC.F5.BIGIP.Disk].FullPathAttr'.Value) 	

				$discoveryFileContent.F5Disks | Where-Object {$_.FullPath -eq $f5DiskFullPathAttr} | ForEach-Object {		  
			
					$FullPath      = $($_.FullPath).ToString()
					$TotalSize     = [float]$_.TotalSize	
					$freeSpace     = [float]$_.Free
					$usedSpace     = [float]$_.InUse
					$freeSpaceInGB = $freeSpace / 1024
					[float]$Threshold			

					if($freeSpace -eq $usedSpace) {			

						$state      = 'Success'
						$supplement = "Disk not in use. Fee: $($freeSpace) Used: $($usedSpace)"

					} else {

						$key = $systemNodeNameKey + 'F5-Disk' + $FullPath				

						if (($Threshold -gt 1) -and ($Threshold -lt 80)) { 
							[float]$diskMinFreePercent = $Threshold / 100
							[float]$diskMinFreeValue   = $TotalSize * $diskMinFreePercent

							if ($freeSpace -ge $diskMinFreeValue) {
								$state      = 'Success'
								$supplement = "Disk free: $($freeSpace) is more than the configured limit of: $($diskMinFreeValue) ; Configured limit in Percent = $($diskMinFreePercent); Threshold: $($Threshold); TotalSize: $($TotalSize) "
							} else {
								$state      = 'Failure'
								$supplement = "Disk free: $($freeSpace) is less than the configured limit of: $($diskMinFreeValue) ; Configured limit in Percent = $($diskMinFreePercent) ; Threshold: $($Threshold); TotalSize: $($TotalSize)"

							}
						} else {
							[float]$diskMinFreePercent = 10 / 100
							[float]$diskMinFreeValue   = $TotalSize * $diskMinFreePercent

							if ($freeSpace -ge $diskMinFreeValue) {
								$state      = 'Success'
								$supplement = "Disk free: $($freeSpace) is more than the configured limit of $($diskMinFreeValue) ; Default limit in Percent = 10%; Threshold: $($Threshold); TotalSize: $($TotalSize)"
							} else {
								$state      = 'Failure'
								$supplement = "Disk free: $($freeSpace) is less than the configured limit of $($diskMinFreeValue);  Default limit in Percent = 10%; Threshold: $($Threshold); TotalSize: $($TotalSize)"

							}
						}

					} 

					$bag = $api.CreatePropertybag()					
					$bag.AddValue("FullPath",$FullPath)
					$bag.AddValue("Key",$key)		
					$bag.AddValue("State",$state)				
					$bag.AddValue("Supplement",$supplement)		
					$bag.AddValue("TestedAt",$testedAt)			
					$bag

				} 
		
			} 		
				
	} elseif ($MonitorItem -eq 'Memory') {
		
		[int]$Threshold		

		$classF5Memory          = Get-SCOMClass -Name 'ABC.F5.BIGIP.Memory'
		$classF5MemoryInstances = Get-SCOMClassInstance -Class $classF5Memory	

		$classF5MemoryInstances | Where-Object {$_.'[ABC.F5.BIGIP.Memory].SystemNodeName'.Value -eq $systemNodeNameKey} | ForEach-Object {						

			$f5Memory    = $_
			[string]$key = [string]$($f5Memory.'[ABC.F5.BIGIP.Memory].Key'.Value) 	

			$discoveryFileContent.F5Memory | ForEach-Object {		
		
				[int]$MemoryTotal  = [int]($_.MemoryTotal / 1024000000)
				[int]$MemoryUsed   = [int]($_.MemoryUsed / 1024000000)
				$MemoryUsedPercent = [int]($_.MemoryUsedPercent)	
				$displayName       = 'F5-Memory' 

				if ($MemoryUsedPercent -le $Threshold) {
					$state      = 'Success'
					$supplement = "Memory percent Used $($MemoryUsedPercent) is less than than the configured limit of: $($Threshold) ; Total Memory in GB: $($MemoryTotal) / Used Memory in GB $($MemoryUsed)"
				} else {
					$state      = 'Failure'
					$supplement = "Memory percent Used $($MemoryUsedPercent) is more than than the configured limit of: $($Threshold) ; Total Memory in GB: $($MemoryTotal) / Used Memory in GB $($MemoryUsed)"
				}	
			
				$bag = $api.CreatePropertybag()								
				$bag.AddValue("Key",$key)		
				$bag.AddValue("State",$state)				
				$bag.AddValue("Supplement",$supplement)		
				$bag.AddValue("TestedAt",$testedAt)			
				$bag
		
			} 
	
		} 
						
	} elseif ($MonitorItem -eq 'Info') {		
	
		$generalInfo    = $($discoveryFileContent.GeneralInfo)
		$productInfo    = $($discoveryFileContent.ProductInfo)
		$productName    = $productInfo.ProductName
		$systemNodeName = $generalInfo.SystemNodeName	
		
		$displayName    = $productName + ' ' + $systemNodeName		

	} else {

	  $FOO = 'Undefined type!'

	}	

  } else {

		$api.LogScriptEvent('ABC.F5.BIGIP MonitorF5SystemHardware.ps1',403,1,"MonitorF5SystemHardwares - strange error")
  
  } 

}  