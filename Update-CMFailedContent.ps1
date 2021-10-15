$SiteCode = "SMS"
$OfflineDPHosts = [System.Collections.Generic.List[string]]::new()
$OnlineDPHosts = [System.Collections.Generic.List[string]]::new()
$failures = Get-WmiObject -Namespace root\sms\site_$SiteCode -Query "SELECT * FROM SMS_PackageStatusDistPointsSummarizer WHERE State <> 0" |
    Select-Object ServerNALPath,LastCopied,PackageType,State,PackageID,SummaryDate |
        ForEach-Object {
            $PKG = Get-WmiObject -NameSpace root\sms\site_$SiteCode -Class SMS_Packagebaseclass -Filter "PackageID = '$($_.PackageID)'" | Select-Object Name,PackageSize
            $server = $_.ServerNALPath.Split("\\")[2]
            if ($OfflineDPHosts -contains $server)
            {
                Write-Host "DP $Server is already known to be offline"
                $Online = "False"
            }
            elseif ($OnlineDPHosts -contains $server)
            {
                Write-Host "DP $Server is already known to be online"
                $Online = "True"   
            }
            if ($OnlineDPHosts -notcontains $server -and $OfflineDPHosts -notcontains $server)
            {
                $Online = (Test-Connection -ComputerName $server -Quiet)
                switch ($Online)
                {
                "True" 
                    {
                        Write-Host "DP $server is Online"
                        $OnlineDPHosts.Add("$server")
                    }
                "False"
                    {
                        Write-Host "DP $server is Offline"
                        $OfflineDPHosts.Add("$server")
                    }
                }
            }
            #$Online = (Test-NetConnection $server).PingSucceeded
            # $Online = (Test-Connection -ComputerName $server)
            $size = $PKG.PackageSize / 1KB
            $State =  switch ($_.State)
                {
                    1 {"Install_Pending"}
                    2 {"Install_Retrying"}
                    3 {"Install_Failed"}
                    4 {"Removal_Pending"}
                    5 {"Removal_Retrying"}
                    6 {"Removal_Failed"}
                    7 {"Instal_Start_Pending"}
                    8 {"Content Validation Failed"}
                }
            $Type = switch ($_.PackageType)
                {
                    0 {"Standard Package"}
                    3 {"Driver Package"}
                    4 {"Task Sequence Package"}
                    5 {"Software Update Package"}
                    6 {"Device Setting Package"}
                    7 {"Virtual App Package"}
                    8 {"Application Package"}
                    257 {"OS Image Package"}
                    258 {"Boot Image Package"}
                    259 {"OS Install Package"}
                }
            $LastCopied = [System.Management.ManagementDateTimeconverter]::ToDateTime($_.LastCopied)
            $SummaryDate = [System.Management.ManagementDateTimeconverter]::ToDateTime($_.SummaryDate)
            New-Object psobject -Property @{
                Name = $PKG.Name
                'PackageSize (MB)' = $size
                PackageType = $Type
                PackageID = $_.PackageID
                State = $State
                StateCode = $_.State
                DistributionPoint = $server
                DpOnline = $Online
                LastCopied = $LastCopied
                SummaryDate = $SummaryDate
                }
        } |
            Select-Object Name,'PackageSize (MB)',PackageType,PackageID,State,StateCode,DistributionPoint,DpOnline,LastCopied,SummaryDate | Sort LastCopied -Descending |
                Out-GridView -Title "Select package/s to redistribute" -OutputMode Multiple |
                 ForEach-Object {
                    Get-WmiObject -Namespace root\sms\site_$SiteCode -Query "SELECT * FROM SMS_DistributionPoint WHERE PackageID='$($_.PackageID)' and ServerNALPath like '%$($_.DistributionPoint)%'" |
                        ForEach-Object {
                            $_.RefreshNow = $true
                            $_.Put()
                        }
                    }
