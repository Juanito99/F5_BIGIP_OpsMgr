param($sourceId,$managedEntityId,$discoveryItem,$tempPath,$f5MonServer)

$api           = New-Object -ComObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

$Global:Error.Clear()
$script:ErrorView      = 'NormalView'
$ErrorActionPreference = 'Continue'

$F5BigIPHosts = Import-Csv -Path $($tempPath + '\' + 'F5-BigIP-Hosts.csv')
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

		if ($discoveryItem -eq 'CPU') {			

			$discoveryFileContent.F5CPU | ForEach-Object {		  
				$cpuID       = $($_.CPUId).ToString()
				$displayName = 'F5-CPU ' + $cpuID + ' On ' + $systemNodeNameKey
				$key         = $systemNodeNameKey + 'F5-CPU' + $cpuID

				$instance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.CPU']$")			
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.CPU']/Id$",$cpuID)	
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.CPU']/SystemNodeName$",$systemNodeNameKey)	
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.CPU']/Key$",$key)
				$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)		
				$discoveryData.AddInstance($instance)
			}	

		} elseif ($discoveryItem -eq 'RemotePath') { 
					
			$shares = Invoke-Expression -Command "net share"		
						
			if ($shares -like "*$tempPath*") {
				$foo = 'Not required to share directory; exiting to avoid empty discovery.'				
				Exit 				
			} else {
				$shareName = 'OurF5InfoForSCOM' + '$'			
				Invoke-Expression -Command "net share $shareName=$tempPath /GRANT:Everyone,READ "						
				#Eventually use icacls to permit domain computers read on the NTFS level.	
				$remotePath  = '\\' + $f5MonServer + '\' + $shareName	
				$displayName = 'F5 MonitoringServer RuntimeInfo for ' + $systemNodeNameKey
				$Key         = $displayName

				$instance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.MonitoringServerRuntimeInfo']$")			
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.MonitoringServerRuntimeInfo']/RemotePath$",$remotePath)	
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.MonitoringServerRuntimeInfo']/Key$",$Key)	
				$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)		
				$discoveryData.AddInstance($instance)
				$discoveryData
			}	
		
		} elseif ($discoveryItem -eq 'Disks') {			

			$discoveryFileContent.F5Disks | ForEach-Object {		
				$FullPath    = $($_.FullPath).ToString()
				$TotalSize   = $([int]($_.TotalSize / 1024)).ToString()
				$displayName = 'F5-Disk ' + $FullPath + ' On ' + $systemNodeNameKey 
				$key         = $systemNodeNameKey + 'F5-Disk' + $FullPath

				$instance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.Disk']$")			
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Disk']/FullPathAttr$",$FullPath)	
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Disk']/TotalSize$",$TotalSize)	
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Disk']/SystemNodeName$",$systemNodeNameKey)
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Disk']/Key$",$key)
				$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)
				$discoveryData.AddInstance($instance)
			}

		} elseif ($discoveryItem -eq 'Memory') {		

			$discoveryFileContent.F5Memory | ForEach-Object {		
				$MemoryTotal = $([int]($_.MemoryTotal / 1024000000)).ToString()		
				$displayName = 'F5-Memory On ' + $systemNodeNameKey  
				$key         = $systemNodeNameKey + 'F5-Memory'
		
				$instance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.Memory']$")						
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Memory']/MemoryTotal$",$MemoryTotal)	
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Memory']/SystemNodeName$",$systemNodeNameKey)	
				$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.Memory']/Key$",$key)	
				$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)	
				$discoveryData.AddInstance($instance)
			}

		} elseif ($discoveryItem -eq 'Info') {				
	
			$generalInfo    = $($discoveryFileContent.GeneralInfo)
			$productInfo    = $($discoveryFileContent.ProductInfo)
			$systemNodeName = $generalInfo.SystemNodeName
			$systemRelease  = $generalInfo.SystemRelease	
			$systemName     = $generalInfo.SystemName
			$productDate    = $productInfo.ProductDate
			$productBuild   = $productInfo.ProductBuild
			$productName    = $productInfo.ProductName
			$productVersion = $productInfo.ProductVersion
			$IPAddress      = [System.Net.Dns]::GetHostByName($systemNodeName).AddressList.IPAddressToString.ToString()

			$displayName    = $productName + ' ' + $systemNodeName + 'F5 System'

			$instance = $discoveryData.CreateClassInstance("$MPElement[Name='ABC.F5.BIGIP.System']$")	
			$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemNodeName$",$systemNodeName)				
			$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemRelease$",$systemRelease)	
			$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/SystemName$",$systemName)				
			$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductDate$",$productDate)			
			$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductBuild$",$productBuild)			
			$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductName$",$productName)			
			$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/ProductVersion$",$productVersion)			
			$instance.AddProperty("$MPElement[Name='ABC.F5.BIGIP.System']/IPAddress$",$IPAddress)		
			$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)
			$discoveryData.AddInstance($instance)

		} else {

		  $FOO = 'Undefined type!'

		}	

	} else {
		
		$api.LogScriptEvent('ABC.F5.BIGIP DiscoveryF5Systems.ps1',403,1,"DiscoveryF5Systems something went wrong. Info No of Objects: $($discoveryFileContent.count)")
  
	} #	END if ($f5HostUrl -ne '') 

} #END foreach($f5HostItem in $F5BigIPHosts)


$discoveryData