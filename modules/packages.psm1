Class WebClient
{
    [System.Net.WebClient]$webClient
    [bool]$downloadComplete
    [object]$downloadProgressChangedEventArgs

    WebClient()
    {
        $this.webClient = New-Object System.Net.WebClient

        if (Get-EventSubscriber -SourceIdentifier 'WebClient.DownloadFileComplete' -ErrorAction SilentlyContinue)
        {
            Unregister-Event -SourceIdentifier WebClient.DownloadFileComplete
        }

        if (Get-EventSubscriber -SourceIdentifier 'WebClient.DownloadProgressChanged' -ErrorAction SilentlyContinue)
        {
            Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
        }

        Register-ObjectEvent $this.webClient DownloadFileCompleted `
            -SourceIdentifier WebClient.DownloadFileComplete `
            -MessageData $this `
            -Action {
                $event.MessageData.downloadComplete = $true
            }

        Register-ObjectEvent $this.webClient DownloadProgressChanged `
            -SourceIdentifier WebClient.DownloadProgressChanged `
            -MessageData $this `
            -Action {
                $event.MessageData.downloadProgressChangedEventArgs = $EventArgs
            }
    }

    [void]DownloadFile($activity, $url, $path)
    {
        $this.downloadComplete = $false
        $this.downloadProgressChangedEventArgs = $null
        
        if (Test-Path $path)
        {
            Remove-Item $path -Force
        }

        $this.webClient.DownloadFileAsync($url, $path)

        Write-Progress -Activity $activity -Status $url -PercentComplete 0
        while (!($this.downloadComplete)) {
            if ($this.downloadProgressChangedEventArgs -and $this.downloadProgressChangedEventArgs.ProgressPercentage) {
                Write-Progress -Activity $activity -Status $url -PercentComplete $this.downloadProgressChangedEventArgs.ProgressPercentage
                $this.downloadProgressChangedEventArgs = $null
            }
        }
    }
}

Class PackageManager
{
    [WebClient]$webClient
    [string]$packagesDir

    PackageManager($packagesDir)
    {
        $this.webClient = [WebClient]::new()
        $this.packagesDir = $packagesDir
    }

    [void]DownloadPackages($packages, $prerelease)
    {
        if (!(Test-Path $packages))
        {
            mkdir $packages | Out-Null
        }

        $downloadPackages = New-Object System.Collections.Generic.List[System.Object]

        foreach($package in $packages)
        {
            $release = $null

            if ($prerelease)
            {
                $release = $package.Releases | Where-Object { $_.Prerelease -match 'true' } | Select-Object -First 1
            }

            if (!$release)
            {
                $release = $package.Releases | Where-Object { $_.prerelease -match 'false' } | Select-Object -First 1
            }

            if (!$release)
            {
                continue
            }

            $downloadPackages.Add(@{
                'Name' = $package.Name;
                'Url' = $release.Url;
                'FileName' = $release.FileName
            });
        }

        $index = 0
        foreach($downloadPackage in $downloadPackages)
        {
            $this.webClient.DownloadFile(
                ("Downloading package {0}/{1} '{2}'" -f ++$index, $downloadPackages.Count, $downloadPackage.Name),
                $downloadPackage.Url,
                (Join-Path $this.packagesDir -ChildPath $downloadPackage.FileName))
        }
    }
}