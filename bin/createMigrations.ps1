$migrationName = $args[0]
$directory = Get-Location
$directory = $directory.Path

Write-Host Current location $directory

class DbContext {
    [string]$FolderPath
    [string]$ContextName
    DbContext([string]$path, [string]$name)
    {
        $this.FolderPath=$path
        $this.ContextName=$name
    }
}

$contexts = (
#[DbContext]::new("SqLiteMigrations", "SqLiteApplicationDbContext"),
[DbContext]::new("MySqlMigrations","MySqlApplicationDbContext")
#[DbContext]::new("MsSqlMigrations","MsSqlApplicationDbContext"),
#[DbContext]::new("PostgreMigrations","PostgreApplicationDbContext")
)

cp $directory\\CommonSettings.targets $directory\\Mapd.Server\
cp $directory\\CommonSettings.targets $directory\\Mapd.Server.Dal\

Write-Host "Build started" -ForegroundColor Yellow

$cleanResult = dotnet clean $directory\\All.sln *>&1
$buildResult = dotnet build $directory\\All.sln *>&1

if($LASTEXITCODE -eq 0)
{
    Write-Host "Build success" -ForegroundColor Green
}
else
{
    $ErrorString = $buildResult -join [System.Environment]::NewLine
}

foreach($context in $contexts)
{
    $path = $context.FolderPath
    $name = $context.ContextName
    $migrationResult = dotnet ef migrations add --project $directory\Mapd.Server.Dal\Mapd.Server.Dal.csproj --startup-project $directory\Mapd.Server\Mapd.Server.csproj --context $name --configuration Debug --no-build $migrationName --output-dir Migrations\$path
    
    if($LASTEXITCODE -eq 0)
    {
        Write-Host "Migration for $name applied"
    }
    else
    {
        Write-Host "Error with $name $migrationResult, stopping..."
        break
    }
}

rm $directory\Mapd.Server\CommonSettings.targets
rm $directory\Mapd.Server.Dal\CommonSettings.targets