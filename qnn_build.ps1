# Define script parameters
param (
    [Parameter(Mandatory = $true)]
    [string]$QAIRT
)

# Define paths
$targetDir = "js\node\bin\napi-v6\win32\arm64"
$aarch64Source = Join-Path -Path $QAIRT -ChildPath "lib\aarch64-windows-msvc"
$hexagonSource = Join-Path -Path $QAIRT -ChildPath "lib\hexagon-v73\unsigned"

# Ensure the target directory exists
if (-Not (Test-Path -Path $targetDir)) {
    Write-Error "Target directory '$targetDir' does not exist. Skipping cleanup."
}
else {
    Write-Host "Target directory '$targetDir' exists."

    Write-Host "Cleaning old QAIRT contents"

    # Delete contents of the target directory except the specified files
    Get-ChildItem -Path $targetDir -File |
        Where-Object { $_.Name -notin "onnxruntime_binding.node", "onnxruntime.dll" } |
        ForEach-Object { Remove-Item -Path $_.FullName -Force }
}

# if (-Not (Test-Path -Path "build")) {
#     Write-Error "Build directory 'build' does not exist. Skipping cleanup."
# }
# else {
#     Write-Host "Build directory 'build' exists. Cleaning prior build"
#     rm -r -fo build
# }

Write-Host "Building QNN NodeJS with '$QAIRT'"
.\build --use_qnn static_lib --build_shared_lib --build_nodejs --build_wheel --skip_tests --qnn_home $QAIRT --cmake_generator "Visual Studio 17 2022" --skip_submodule_sync --config Release --build_dir build\Windows

if ($LASTEXITCODE -ne 0) {
    Write-Error "🤦 Build script failed. WAT! 🦆"
    exit 1
}

# Ensure the source directories exist
if (-Not (Test-Path -Path $aarch64Source)) {
    Write-Error "Source directory '$aarch64Source' does not exist."
    exit 1
}

if (-Not (Test-Path -Path $hexagonSource)) {
    Write-Error "Source directory '$hexagonSource' does not exist."
    exit 1
}

Write-Host "Copying contents of aarch64 and hexagon-v73"
Copy-Item -Path "$aarch64Source\*" -Destination $targetDir -Recurse -Force
Copy-Item -Path "$hexagonSource\*" -Destination $targetDir -Recurse -Force

Write-Host "Operation completed successfully."
