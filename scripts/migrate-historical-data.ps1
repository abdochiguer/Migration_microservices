param(
    [string]$SourceNamespace = "default",
    [string]$TargetNamespace = "microservices"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Migration des Données Historiques (demo-db -> vet-db)     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Récupération des pods
Write-Host "Recherche du pod PostgreSQL source..." -ForegroundColor Gray
$sourcePod = (kubectl get pods -n $SourceNamespace -l app=demo-db -o jsonpath="{.items[0].metadata.name}")

Write-Host "Recherche du pod PostgreSQL cible..." -ForegroundColor Gray
$targetPod = (kubectl get pods -n $TargetNamespace -l app=vet-db -o jsonpath="{.items[0].metadata.name}")

if (-not $sourcePod -or -not $targetPod) {
    Write-Host "Erreur : Les pods demo-db ou vet-db ne sont pas trouvés !" -ForegroundColor Red
    exit 1
}

Write-Host "Pod source : $sourcePod ($SourceNamespace)" -ForegroundColor Green
Write-Host "Pod cible  : $targetPod ($TargetNamespace)" -ForegroundColor Green

# 2. Dump des tables cibles depuis le pod source
Write-Host "`n[1/2] Extraction des tables 'vets', 'specialties', 'vet_specialties'..." -ForegroundColor Yellow
$dumpCmd = "PGPASSWORD=pass pg_dump -U user -d petclinic --data-only --inserts -t vets -t specialties -t vet_specialties"
$sqlData = kubectl exec -n $SourceNamespace $sourcePod -- sh -c "$dumpCmd"

if (-not $sqlData) {
    Write-Host "Attention : Aucune donnée extraite ou échec de pg_dump." -ForegroundColor Red
    exit 1
}

# 3. Injection dans le pod cible
Write-Host "[2/2] Injection dans la base du microservice vet-db..." -ForegroundColor Yellow
$sqlData | kubectl exec -i -n $TargetNamespace $targetPod -- sh -c "PGPASSWORD=vetpass psql -U vetuser -d vetdb"

# 4. Vérification
Write-Host "`n=== Vérification du résultat ===" -ForegroundColor Cyan
kubectl exec -n $TargetNamespace $targetPod -- sh -c "PGPASSWORD=vetpass psql -U vetuser -d vetdb -c 'SELECT count(*) AS total_vets FROM vets; SELECT count(*) AS total_specialties FROM specialties;'"
Write-Host "`nMigration des données historiques terminée !" -ForegroundColor Green
