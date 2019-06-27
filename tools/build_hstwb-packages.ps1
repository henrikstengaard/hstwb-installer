# Build Packages List
# -------------------
# Author: Henrik Noerfjand Stengaard
# Date:   2019-03-29
#
# A powershell script to build HstWB packages from HstWB repositories.


Param(
	[Parameter(Mandatory=$false)]
	[string]$githubAccessToken
)

Class PackagesList
{
    [string]$Date
    [string]$Description
    [string]$Url
    [array]$Packages

    PackagesList($date, $description, $url, $packages)
    {
        $this.Date = $date
        $this.Description = $description
        $this.Url = $url
        $this.Packages = $packages
    }
}

Class Package
{
    [string]$Name
    [array]$Releases

    Package($name, $releases)
    {
        $this.Name = $name
        $this.Releases = $releases
    }
}

Class Release
{
    [string]$Prerelease
    [string]$Version
    [string]$Url
    [string]$FileName

    Release($prerelease, $version, $url, $fileName)
    {
        $this.Prerelease = $prerelease
        $this.Version = $version
        $this.Url = $url
        $this.FileName = $fileName
    }
}

Class PackageManager
{
    [string]$githubAccessToken

    PackageManager($githubAccessToken)
    {
        $this.githubAccessToken = $githubAccessToken
    }

    [array]GetPackages($repositories)
    {
        $packages = New-Object System.Collections.Generic.List[System.Object]

        foreach($repository in $repositories)
        {
            if ($repository.Type -ne 'github')
            {
                continue
            }
        
            $package = $this.GetGithubPackage($repository.Url)

            if (!$package)
            {
                continue
            }

            $packages.Add($package)
        }

        return $packages.ToArray()
    }

    [Package]GetGithubPackage($githubUrl)
    {
        # set headers
        $headers = @{}
        if ($this.githubAccessToken -and $this.githubAccessToken -ne '')
        {
            $headers.Authorization = 'token {0}' -f $this.githubAccessToken
        }

        # get github package json
        $githubPackageUrl = $githubUrl -replace 'https://[^\.]*?github.com', 'https://api.github.com/repos'
        $githubPackage = Invoke-RestMethod -Uri $githubPackageUrl -Method Get -Headers $headers

        # get github releases json
        $githubReleasesUrl = '{0}/releases' -f $githubPackageUrl
        $githubReleases = Invoke-RestMethod -Uri $githubReleasesUrl -Method Get -Headers $headers

        # build releases
        $releases = New-Object System.Collections.Generic.List[System.Object]
        foreach ($githubRelease in $githubReleases)
        {
            $asset = $githubRelease.assets | Select-Object -First 1

            if (!$asset)
            {
                return $null
            }
    
            $release = [Release]::new(
                $githubRelease.prerelease,
                $githubRelease.tag_name,
                $asset.browser_download_url,
                $asset.name)
            $releases.Add($release)
        }

        return [Package]::new(
            $githubPackage.name,
            $releases.ToArray())
    }
}

# paths
$hstwbRepositoriesJsonFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('..\data\hstwb-repositories.json')
$hstwbPackagesJsonFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('..\data\hstwb-packages.json')

# create package manager
$packageManager = [PackageManager]::new($githubAccessToken)

# read hstwb repositories json file
$repositoriesMetadata = Get-Content $hstwbRepositoriesJsonFile -Raw | ConvertFrom-Json

# get packages from hstwb repositories
$packages = $packageManager.GetPackages($repositoriesMetadata.Repositories)

# create packages list with date, description, url and packages
$packagesList = [PackagesList]::new(
    (Get-Date -format "yyyy-MM-dd HH:mm:ss"),
    'HstWB packages',
    'https://hstwb.firstrealize.com/data/hstwb-packages.json',
    $packages
)

# write hstwb packages json file
$hstwbPackagesJson = $packagesList | ConvertTo-Json -Depth 4
Set-Content -Path $hstwbPackagesJsonFile -Value $hstwbPackagesJson -NoNewline