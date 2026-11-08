param(
    [Parameter(Mandatory=$true)]
    [string]$SiteName,

    [Parameter(Mandatory=$false)]
    [string]$Description = "Website được tạo và quản trị tự động bởi Antigravity AI",

    [Parameter(Mandatory=$false)]
    [string]$SourceDir = ""
)

$ErrorActionPreference = "Stop"
$env:Path = "C:\Users\Dell\.gemini\antigravity\scratch\tools\git\cmd;C:\Users\Dell\.gemini\antigravity\scratch\tools\gh\bin;" + $env:Path

$ghUser = (gh api user --jq .login).Trim()
if (-not $ghUser) {
    Write-Error "Chưa đăng nhập GitHub CLI. Hãy chạy: gh auth login --web"
    exit 1
}

$baseScratch = "C:\Users\Dell\.gemini\antigravity\scratch"
$siteDir = if ($SourceDir -ne "") { $SourceDir } else { Join-Path $baseScratch $SiteName }

if (-not (Test-Path $siteDir)) {
    New-Item -ItemType Directory -Path $siteDir -Force | Out-Null
}

$indexFile = Join-Path $siteDir "index.html"
if (-not (Test-Path $indexFile)) {
    @"
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$SiteName</title>
  <style>
    body { font-family: system-ui, sans-serif; background: #0f172a; color: #f8fafc; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
    .box { background: #1e293b; border: 1px solid #334155; padding: 2.5rem; border-radius: 16px; max-width: 600px; text-align: center; }
    h1 { color: #38bdf8; margin-top: 0; }
    p { color: #94a3b8; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="box">
    <h1>$SiteName</h1>
    <p>$Description</p>
  </div>
</body>
</html>
"@ | Set-Content -Path $indexFile -Encoding UTF8
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

    $repoExists = $false
    try {
        gh repo view "$ghUser/$SiteName" | Out-Null
        $repoExists = $true
    } catch {
        $repoExists = $false
    }

    if (-not $repoExists) {
        gh repo create $SiteName --public --description $Description --source=. --remote=origin --push
    } else {
        git push -u origin main --force
    }

    # Enable GitHub Pages on main branch
    try {
        gh api -X POST "repos/$ghUser/$SiteName/pages" -f "source[branch]=main" -f "source[path]=/" | Out-Null
    } catch {
        # Pages might already be enabled
    }

    $liveUrl = "https://$ghUser.github.io/$SiteName/"
    Write-Output "PUBLISHED_URL=$liveUrl"
} finally {
    Pop-Location
}
