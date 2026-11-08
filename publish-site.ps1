param(
    [Parameter(Mandatory=$true)]
    [string]$SiteName,

    [Parameter(Mandatory=$false)]
    [string]$Description = "Website duoc tao va quan tri tu dong boi Antigravity AI",

    [Parameter(Mandatory=$false)]
    [string]$SourceDir = ""
)

$ErrorActionPreference = "Continue"
$env:Path = "C:\Users\Dell\.gemini\antigravity\scratch\tools\git\cmd;C:\Users\Dell\.gemini\antigravity\scratch\tools\gh\bin;" + $env:Path

gh auth setup-git

$ghUser = (gh api user --jq .login).Trim()
if (-not $ghUser) {
    Write-Error "Chua dang nhap GitHub CLI."
    exit 1
}

$baseScratch = "C:\Users\Dell\.gemini\antigravity\scratch"
$siteDir = if ($SourceDir -ne "") { $SourceDir } else { Join-Path $baseScratch $SiteName }

if (-not (Test-Path $siteDir)) {
    New-Item -ItemType Directory -Path $siteDir -Force | Out-Null
}

Push-Location $siteDir
try {
    if (-not (Test-Path ".git")) {
        git init -b main
    }
    git config user.name $ghUser
    git config user.email "$ghUser@users.noreply.github.com"
    git add -A
    git commit -m "Update website content" --allow-empty

    gh repo view "$ghUser/$SiteName" >$null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Output "Creating repository $ghUser/$SiteName..."
        gh repo create "$ghUser/$SiteName" --public --description "$Description" --source=. --remote=origin --push
    } else {
        $remotes = git remote
        if ($remotes -notcontains "origin") {
            git remote add origin "https://github.com/$ghUser/$SiteName.git"
        }
        git push -u origin main --force
    }

    # Enable GitHub Pages on main branch
    gh api -X POST "repos/$ghUser/$SiteName/pages" -f "source[branch]=main" -f "source[path]=/" >$null 2>&1

    if ($SiteName -eq "$ghUser.github.io") {
        $liveUrl = "https://$ghUser.github.io/"
    } else {
        $liveUrl = "https://$ghUser.github.io/$SiteName/"
    }
    Write-Output "PUBLISHED_URL=$liveUrl"
} finally {
    Pop-Location
}
