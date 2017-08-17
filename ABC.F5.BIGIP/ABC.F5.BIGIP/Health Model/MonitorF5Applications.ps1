param($MonitorItem, $Threshold)

$api = New-Object -ComObject 'MOM.ScriptAPI'

$Global:Error.Clear()
$script:ErrorView      = 'NormalView'
$ErrorActionPreference = 'Continue'

$classF5MonServerRuntimeInfo         = Get-SCOMClass -Name 'ABC.F5.BIGIP.MonitoringServerRuntimeInfo'
$classF5MonServerRuntimeInfoInstance = Get-SCOMClassInstance -Class $classF5MonServerRuntimeInfo

$tempPath = $classF5MonServerRuntimeInfoInstance.'[ABC.F5.BIGIP.MonitoringServerRuntimeInfo].RemotePath'.Value
$testedAt = "Tested on: $(Get-Date -Format u) / $(([TimeZoneInfo]::Local).DisplayName)"

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
				
		if ($MonitorItem -eq 'PoolStatus') {

			$classF5PoolStatus          = Get-SCOMClass -Name 'ABC.F5.BIGIP.PoolStatus'
			$classF5PoolStatusInstances = Get-SCOMClassInstance -Class $classF5PoolStatus		

			$classF5PoolStatusInstances | Where-Object {$_.'[ABC.F5.BIGIP.PoolStatus].SystemNodeName'.Value -eq $systemNodeNameKey} | ForEach-Object {						

				$f5PoolStatus = $_

				[string]$f5PoolStatusName = [string]$($f5PoolStatus.'[ABC.F5.BIGIP.PoolStatus].PoolStatusName'.Value)
				[string]$key              = [string]$($f5PoolStatus.'[ABC.F5.BIGIP.PoolStatus].Key'.Value) 				
							
				$discoveryFileContent.PoolStatus | Where-Object {$_.ltmPoolStatusName -eq $f5PoolStatusName} | ForEach-Object {		  
							
					$poolName         = $_.ltmPoolStatusName
					$displayName      = 'F5-Pool' + $poolName
					$key              = $systemNodeNameKey + $displayName
					$poolEnabledState = $_.ltmPoolStatusEnabledState
					$poolAvailStatus  = $_.ltmPoolStatusAvailState			
					$rawInfo          = "PoolName: $($poolName) Key: $($key) System: $($poolEnabledState)"			
				
					If($poolEnabledState -eq "Enabled" ) {
						if($poolAvailStatus -eq "green") {
							$state      = 'Green'
							$supplement = "PoolStatus is green."
						} elseif($poolAvailStatus -eq "blue")  {
							$state      = 'Green'
							$supplement = "PoolStatus is not green, but still ok. - Current color code: $($poolAvailStatus)"
						} elseif($poolAvailStatus -eq "yellow") {
							$state      = 'Yellow'
							$supplement = "PoolStatus is yellow. - Current color code: $($poolAvailStatus)"						
						} elseif($poolAvailStatus -eq "red")  {
							$state      = 'Red'
							$supplement = "PoolStatus is red. - Current color code: $($poolAvailStatus)"
						} else {
							$state      = 'Yellow'
							$supplement = "PoolStatus is not green. - Current color code: $($poolAvailStatus)"
						}
					} else {
						$state      = 'Green'
						$supplement = "PoolStatus not enabled. - Not in use, so also no problem."
					}							

					$bag = $api.CreatePropertybag()					
					$bag.AddValue("PoolName",$poolName)
					$bag.AddValue("Key",$key)		
					$bag.AddValue("State",$state)				
					$bag.AddValue("Supplement",$supplement)		
					$bag.AddValue("TestedAt",$testedAt)			
					$bag

				} 
		
			} 

		} elseif ($MonitorItem -eq 'NodeAddr') {	

			$classF5NodeAddr          = Get-SCOMClass -Name 'ABC.F5.BIGIP.NodeAddress'
			$classF5NodeAddrInstances = Get-SCOMClassInstance -Class $classF5NodeAddr			

			$classF5NodeAddrInstances | Where-Object {$_.'[ABC.F5.BIGIP.NodeAddress].SystemNodeName'.Value -eq $systemNodeNameKey} | ForEach-Object {						
				
				$f5NodeAddr             = $_
				[string]$f5NodeAddrName = [string]$($f5NodeAddr.'[ABC.F5.BIGIP.NodeAddress].NodeAddressName'.Value)
				[string]$key            = [string]$($f5NodeAddr.'[ABC.F5.BIGIP.NodeAddress].Key'.Value) 			
							
				$discoveryFileContent.NodeAddrTable | Where-Object {$_.ltmNodeAddrName -eq $f5NodeAddrName} | ForEach-Object {		  		
							
					$nodeAddressName         = $_.ltmNodeAddrName
					$displayName             = 'F5-NodeAddress' + $nodeAddressName
					$key                     = $systemNodeNameKey + $displayName						
					$nodeAddressMonitorRule  = $_.ltmNodeAddrMonitorRule
					$nodeAddrMonitorStatus   = $_.ltmNodeAddrMonitorStatus
					$nodeAddressEnabledState = $_.ltmNodeAddrEnabledState			
					$nodeAddrSessionStatus   = $_.ltmNodeAddrSessionStatus
			
					$rawInfo                 = "NodeAddrName: $($nodeAddressName) Key: $($key) EnableState: $($nodeAddressEnabledState)"				

					If($nodeAddrSessionStatus -ieq "Enabled" ) {
						if($nodeAddrMonitorStatus -ieq "up") {
							$state      = 'Green'
							$supplement = "NodeAddr is up."
						} else {
							$state      = 'Red'
							$supplement = "NodeAddr is not up. - Current Status: $($nodeAddrMonitorStatus) "
						}
					} else {
						$state      = 'Green'
						$supplement = "NodeAddr not enabled. - Not in use, so also no problem."
					}							

					$bag = $api.CreatePropertybag()					
					$bag.AddValue("NodeAddrName",$nodeAddressName)
					$bag.AddValue("Key",$key)		
					$bag.AddValue("State",$state)				
					$bag.AddValue("Supplement",$supplement)		
					$bag.AddValue("TestedAt",$testedAt)			
					$bag

				} 		
		} 				
	
	} elseif ($MonitorItem -eq 'TrafficGroup') {
				
		[string]$Threshold		

		$classF5TrafficGroupItem          = Get-SCOMClass -Name 'ABC.F5.BIGIP.TrafficGroupItem'
		$classF5TrafficGroupItemInstances = Get-SCOMClassInstance -Class $classF5TrafficGroupItem	

		$classF5TrafficGroupItemInstances | Where-Object {$_.'[ABC.F5.BIGIP.TrafficGroupItem].SystemNodeName'.Value -eq $systemNodeNameKey} | ForEach-Object {						
					
			$discoveryFileContent.TrafficGroupStatusTable | ForEach-Object {		
		
				$groupDeviceName     = $_.sysCmTrafficGroupStatusDeviceName
				$groupFailoverStatus = $_.sysCmTrafficGroupStatusFailoverStatus
				$groupName           = $_.sysCmTrafficGroupStatusTrafficGroup			
					
				$displayName         = 'F5-Traffic Group Item ' + $groupName + '-' + $groupDeviceName + ' On ' + $systemNodeNameKey  
				$key                 = $systemNodeNameKey + 'F5-TrafficGroupItem' + $groupName + $groupDeviceName		
				$key                 = $key.replace('/','').replace('-','')		
				
				if($Threshold) {
					$Threshold += '|^active|^standby'
				} else {
					$Threshold  = '^active|^standby'
				}

				if ($groupFailoverStatus -match $Threshold) {
					$state      = 'Green'
					$supplement = "FailoverStatus: $($groupFailoverStatus) matches on state of $($Threshold) "
				} else {
					$state      = 'Red'
					$supplement = "FailoverStatus: $($groupFailoverStatus) not matches on state of $($Threshold) "
				}	
			
				$bag = $api.CreatePropertybag()								
				$bag.AddValue("Key",$key)		
				$bag.AddValue("State",$state)				
				$bag.AddValue("Supplement",$supplement)		
				$bag.AddValue("TestedAt",$testedAt)			
				$bag		
			} 
	
		} 		
	
	} elseif ($MonitorItem -eq 'SyncStatus') {
				
		[string]$Threshold		

		$classF5SyncStatusItem          = Get-SCOMClass -Name 'ABC.F5.BIGIP.SyncStatusItem'
		$classF5SyncStatusItemInstances = Get-SCOMClassInstance -Class $classF5SyncStatusItem	

		$classF5SyncStatusItemInstances | Where-Object {$_.'[ABC.F5.BIGIP.SyncStatusItem].SystemNodeName'.Value -eq $systemNodeNameKey} | ForEach-Object {									

			$discoveryFileContent.SyncStatusDetails | ForEach-Object {		
		
				$syncStateItemPart = $_.sysCmSyncStatusDetailsDetails				
				$syncItemName      = $syncStateItemPart.Substring(0, $syncStateItemPart.IndexOf(' ')).replace(':','')				
				$displayName       = 'F5-SyncStatus Item ' + $syncItemName  + ' On ' + $systemNodeNameKey  
				$key               = $systemNodeNameKey + 'F5-SyncStatusItem' + $syncItemName									
				$itemState         = $syncStateItemPart.Substring($syncStateItemPart.IndexOf(' '),$syncStateItemPart.Length - $syncStateItemPart.IndexOf(' '))
				$itemState         = $itemState.replace('(','').replace(')','').trim()				

				if($Threshold) {
					$Threshold += '|^connected|^in\s{1}sync'
				} else {
					$Threshold  = '^connected|^in\s{1}sync'
				}

				if ($itemState -imatch $Threshold) {
					$state      = 'Green'
					$supplement = "SyncStatus: $($itemState) matches on state of $($Threshold) "
				} else {
					$state      = 'Red'
					$supplement = "SyncStatus: $($itemState) not matches on state of $($Threshold) "
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

		$api.LogScriptEvent('ABC.F5.BIGIP Monitor F5Applications.ps1',403,1,"Monitor F5Applications - strange error")
  
  } 

} 