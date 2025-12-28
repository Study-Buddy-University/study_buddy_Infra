# AI Study Buddy - Windows GPU Configuration Script
# This script automatically detects your GPU and configures the .env file

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AI Study Buddy - GPU Configuration Script" -ForegroundColor Cyan
Write-Host "  Windows 11 Edition" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to detect NVIDIA GPU
function Get-NvidiaGPU {
    try {
        $nvidiaOutput = & nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>$null
        if ($LASTEXITCODE -eq 0 -and $nvidiaOutput) {
            return @{
                Found = $true
                Type = "nvidia"
                Info = $nvidiaOutput
            }
        }
    }
    catch {
        # nvidia-smi not found or error
    }
    return @{ Found = $false }
}

# Function to detect AMD GPU
function Get-AmdGPU {
    try {
        # Check if AMD GPU exists via WMI
        $amdGPU = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -like "*AMD*" -or $_.Name -like "*Radeon*" }
        if ($amdGPU) {
            return @{
                Found = $true
                Type = "amd"
                Info = $amdGPU.Name
            }
        }
    }
    catch {
        # Error checking AMD GPU
    }
    return @{ Found = $false }
}

# Function to update .env file
function Update-EnvFile {
    param (
        [string]$GpuType,
        [int]$GpuCount
    )
    
    $envPath = ".env"
    $envExamplePath = ".env.example"
    
    # Check if .env exists, if not create from .env.example
    if (-not (Test-Path $envPath)) {
        if (Test-Path $envExamplePath) {
            Write-Host "Creating .env file from .env.example..." -ForegroundColor Yellow
            Copy-Item $envExamplePath $envPath
        }
        else {
            Write-Host "Error: .env.example not found!" -ForegroundColor Red
            Write-Host "Please ensure you're running this script from the infrastructure/ directory" -ForegroundColor Red
            return $false
        }
    }
    
    # Read .env file
    $envContent = Get-Content $envPath -Raw
    
    # Update or add GPU_TYPE
    if ($envContent -match "GPU_TYPE=.*") {
        $envContent = $envContent -replace "GPU_TYPE=.*", "GPU_TYPE=$GpuType"
    }
    else {
        $envContent += "`nGPU_TYPE=$GpuType"
    }
    
    # Update or add GPU_COUNT
    if ($envContent -match "GPU_COUNT=.*") {
        $envContent = $envContent -replace "GPU_COUNT=.*", "GPU_COUNT=$GpuCount"
    }
    else {
        $envContent += "`nGPU_COUNT=$GpuCount"
    }
    
    # Write back to .env
    Set-Content -Path $envPath -Value $envContent
    
    Write-Host ""
    Write-Host "✅ Configuration saved to .env file" -ForegroundColor Green
    Write-Host "   GPU_TYPE=$GpuType" -ForegroundColor Green
    Write-Host "   GPU_COUNT=$GpuCount" -ForegroundColor Green
    
    return $true
}

# Main script execution
Write-Host "🔍 Detecting GPU hardware..." -ForegroundColor Yellow
Write-Host ""

# Detect NVIDIA GPU
$nvidiaGPU = Get-NvidiaGPU
if ($nvidiaGPU.Found) {
    Write-Host "✅ NVIDIA GPU Detected!" -ForegroundColor Green
    Write-Host "   Model: $($nvidiaGPU.Info)" -ForegroundColor Cyan
    Write-Host ""
    
    $response = Read-Host "Enable GPU acceleration? (Y/n)"
    if ($response -eq "" -or $response -eq "y" -or $response -eq "Y") {
        $success = Update-EnvFile -GpuType "nvidia" -GpuCount 1
        
        if ($success) {
            Write-Host ""
            Write-Host "================================================" -ForegroundColor Green
            Write-Host "  GPU Configuration Complete!" -ForegroundColor Green
            Write-Host "================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Yellow
            Write-Host "  1. Ensure Docker Desktop is running" -ForegroundColor White
            Write-Host "  2. Ensure NVIDIA Container Toolkit is installed in WSL" -ForegroundColor White
            Write-Host "     (See WINDOWS_SETUP_GUIDE.md for instructions)" -ForegroundColor White
            Write-Host "  3. Start the application:" -ForegroundColor White
            Write-Host "     docker compose up -d" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "⚡ GPU acceleration will be enabled for AI inference!" -ForegroundColor Green
        }
    }
    else {
        Write-Host "GPU acceleration disabled. Using CPU mode." -ForegroundColor Yellow
        Update-EnvFile -GpuType "none" -GpuCount 0
    }
    exit 0
}

# Detect AMD GPU
$amdGPU = Get-AmdGPU
if ($amdGPU.Found) {
    Write-Host "⚠️  AMD GPU Detected!" -ForegroundColor Yellow
    Write-Host "   Model: $($amdGPU.Info)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Note: AMD GPU support requires ROCm, which has limited Windows support." -ForegroundColor Yellow
    Write-Host "For best results, consider using NVIDIA GPUs or CPU mode." -ForegroundColor Yellow
    Write-Host ""
    
    $response = Read-Host "Configure for AMD GPU anyway? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        Update-EnvFile -GpuType "amd" -GpuCount 1
        Write-Host ""
        Write-Host "AMD GPU configured. Note that this is experimental on Windows." -ForegroundColor Yellow
    }
    else {
        Write-Host "Using CPU mode instead." -ForegroundColor Yellow
        Update-EnvFile -GpuType "none" -GpuCount 0
    }
    exit 0
}

# No GPU detected
Write-Host "ℹ️  No GPU detected" -ForegroundColor Yellow
Write-Host ""
Write-Host "The application will run in CPU-only mode." -ForegroundColor White
Write-Host "This is still functional but will be slower for AI inference." -ForegroundColor White
Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Yellow
Write-Host "  • Use smaller models (qwen2.5:0.5b, gemma2:2b)" -ForegroundColor White
Write-Host "  • Consider upgrading to a system with NVIDIA GPU" -ForegroundColor White
Write-Host ""

$response = Read-Host "Continue with CPU-only mode? (Y/n)"
if ($response -eq "" -or $response -eq "y" -or $response -eq "Y") {
    $success = Update-EnvFile -GpuType "none" -GpuCount 0
    
    if ($success) {
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Green
        Write-Host "  CPU Configuration Complete!" -ForegroundColor Green
        Write-Host "================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Start the application:" -ForegroundColor White
        Write-Host "     docker compose up -d" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "💻 Application will run in CPU mode" -ForegroundColor Cyan
    }
}
else {
    Write-Host "Configuration cancelled." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "For more information, see:" -ForegroundColor Cyan
Write-Host "  • WINDOWS_SETUP_GUIDE.md" -ForegroundColor White
Write-Host "  • GPU_SETUP.md" -ForegroundColor White
Write-Host ""
