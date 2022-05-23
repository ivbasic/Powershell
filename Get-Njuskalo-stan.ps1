#### OUTDATED SCRIPT! ####

do{
    $lokacija = "1248" 
    # crnomerec   | 1248
    # maksimir    | 1253
    # donjigdrad  | 1250
    # gornjigrad  | 1252
    $kvadrati = "50" 
    $cijena = "300" # €

    #### njuskalo site i rezultati
    $site = "njuskalo.hr/iznajmljivanje-stanova?locationId=" + $lokacija + "&price%5Bmax%5D=" + $cijena + "$si&mainArea%5Bmin%5D=" + $kvadrati + "&flatTypeId=183"

    $HTML = Invoke-WebRequest -Uri $site
    $Results = $null
    $Results = ($HTML.ParsedHtml.getElementsByTagName(‘li’) | 
    Where{ $_.className -like 'EntityList-item EntityList-item--Regular EntityList-item--n1*' } ).innertext 

    #### Prvi oglas i uređeni lijepsi oglas
    $PrviOglas,$2 = $Results.split('~')
    $LijepOglas = $PrviOglas -creplace '(?m)^\s*\r?\n',''

    #### Splitanje oglasa
    $OglasNaslov = ($LijepOglas -split '\n')[0] 
    $OglasSlika = ($LijepOglas -split '\n')[1]
    $OglasKat = ($LijepOglas -split '\n')[2] 
    $OglasKvadrati = ($LijepOglas -split '\n')[3]
    $OglasObjavljen = ($LijepOglas -split '\n')[4] 
    $OglasSpremiOglas = ($LijepOglas -split '\n')[5] 
    $OglasPrikaziNaMapi = ($LijepOglas -split '\n')[6] 
    $OglasCijenaKn = ($LijepOglas -split '\n')[7] 
    $OglasCijenaE = ($LijepOglas -split '\n')[8] 

    #### Select linka od novog oglasa
    $link = ($HTML.ParsedHtml.getElementsByTagName('li') |
      Where-Object { $_.className -like 'EntityList-item EntityList-item--Regular EntityList-item--n1*' } |
      ForEach-Object { $_.getElementsByTagName('a') } |
      Where-Object { $_.className -eq 'link' } |
      Select-Object -Expand pathname)[0].Substring(1)
    $oglas = "www.njuskalo.hr" + $link

    #### If novi oglas
    if (Compare-Object $Results $Store)
    {
        $bot = "https://api.telegram.org/botTOKEN/sendmessage?chat_id=CHATID&text=" + $oglas
        (New-Object -Com Shell.Application).Open($bot)
        echo $oglas
    }
    else
    {
        $datum = Get-Date -Format g  
        Write-Host "Nema novih oglasa" - $datum      
    }

    $Store = $Results
    start-sleep -Seconds 300

} until($infinity)
