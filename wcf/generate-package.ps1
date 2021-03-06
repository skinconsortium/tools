##
# generate wcf package script
##
cls
function generate-package($sourceDirectoy=$args[0])
{
    # include 7zip to enviroment
    $env:path = "c:\windows\system32;c:\Program Files\7-Zip"
    set-alias sevenzip 7z
    
    $Host.UI.RawUI.WindowTitle = "Generate Package"
    $myheadlinecolor = "red"
    $myheadlinecolor2 = "green"
    $packageXmlFile = resolve-path(".\package.xml")
    if (test-path $packageXmlFile.toString() -pathType leaf)
    {
        write-host "Parsing package.xml..."  -ForegroundColor $myheadlinecolor  
 
        [System.Xml.XmlReaderSettings] $readerSettings = new-object System.Xml.XmlReaderSettings
        $readerSettings.ValidationType = [System.Xml.ValidationType]::None
        $readerSettings.ProhibitDtd = $false
        $readerSettings.XmlResolver = $null;
        #$readerSettings.IgnoreProcessingInstructions = $true;  
              
        [System.Xml.XmlReader] $reader = [System.Xml.XmlReader]::Create($packageXmlFile, $readerSettings)
          
        [System.Xml.XmlDocument] $packageXml = new-object System.Xml.XmlDocument        
        $packageXml.load($reader)
        $reader.close()
        
        $packageId = $packageXml.selectSingleNode("package").getAttribute("name")
        write-host "  Package Identifier: $packageId" -ForegroundColor $myheadlinecolor2
	$Host.UI.RawUI.WindowTitle = "Generating Package: $packageId"
        $packageVersion = $packageXml.selectSingleNode("/package/packageinformation/version").get_InnerXml()
        write-host "  Last Package Version: $packageVersion" -ForegroundColor $myheadlinecolor2
        write-host "  Last Package Date:"$packageXml.selectSingleNode("/package/packageinformation/date").get_InnerXml() -ForegroundColor $myheadlinecolor2
        $packageVersionChars = $packageVersion.ToCharArray()
        $i = $packageVersionChars.length-1
        for($i; $i -ge 0; $i--)
        {
            if (($packageVersionChars[$i] -lt '0') -or ($packageVersionChars[$i] -gt '9'))
            {
                $i++
                break
            }
        }
        $len = $packageVersion.length -1
        $packageVersionNew = [int32]$packageVersion.substring($i, $packageVersion.length-$i)
        $packageVersionNew++
        $packageVersion = $packageVersion.substring(0, $i) + $packageVersionNew
        write-host ""
        write-host "Updating package.xml..." -ForegroundColor $myheadlinecolor       
        write-host "  New Package Version: $packageVersion" -ForegroundColor $myheadlinecolor2
        write-host "  New Package Date:"(get-date -uformat %Y-%m-%d) -ForegroundColor $myheadlinecolor2
        $packageXml.selectSingleNode("/package/packageinformation/version").set_InnerXml($packageVersion)
        $packageXml.selectSingleNode("/package/packageinformation/date").set_InnerXml((get-date -uformat %Y-%m-%d))
        
        [System.Xml.XmlWriterSettings] $writerSettings = new-object System.Xml.XmlWriterSettings
        $writerSettings.Indent = $true
        $writerSettings.IndentChars = "`t";
        $writersettings.encoding = [System.Text.Encoding]::UTF8
        
        [System.Xml.XmlWriter] $writer = [System.Xml.XmlWriter]::Create($packageXmlFile, $writerSettings)
        
        $packageXml.save($writer)
        $writer.close();
        
        write-host ""
        Write-Host "Deleting old Archives..." -ForegroundColor $myheadlinecolor    
        del "*.tar"
        del "*.gz"
	del "*.tmp"
        
        $additionalIncludeDirs = @()
        
    	foreach($dir in (ls | ? { $_.GetType() -like 'System.IO.DirectoryInfo'}))
    	{
    		if (test-path  ".\$dir" -pathType container)
    		{
                $nozip = 0
    		    write-host ""
    		    Write-Host "Synchronizing $dir..." -ForegroundColor $myheadlinecolor
    		    
    		    write-host "  Copying from Source Directory" -ForegroundColor $myheadlinecolor2
    		    $srcdir = $sourceDirectoy
    		    switch ($dir)
                {
        		    "acptemplates"
                    {
        			     $srcdir += "/acp/templates"
                         break
        		    }
        		    "templates"
        		    {
        			     $srcdir += "/templates"
                         break
        		    }
        		    {($_ -like "requirements") -or ($_ -like"optionals")}           
        		    {
        			     $srcdir = "../tarballs"
                         $nozip = 1
                         $additionalIncludeDirs += './'+$dir+'*/*.tar'
                         $additionalIncludeDirs += './'+$dir+'*/*/*.tar'
                         break
        		    }                
                }        
    		    robocopy $srcdir/ ./$dir "*.*" /S /XL 

    		    write-host ""
                if ($nozip -eq 0)
                {
        		    write-host "  Storing in Tarball Archive" -ForegroundColor $myheadlinecolor2
        		    sevenzip a -r -ttar "-x!.svn" "-x!.psd" "-x!.svg" ./$dir.tar ./$dir/*
                }
    		}
    	}
        
         write-host ""
         Write-Host "Creating Final Package..." -ForegroundColor $myheadlinecolor
         write-host "  Storing in Tarball Archive" -ForegroundColor $myheadlinecolor2
         sevenzip a -ttar "-x!*.cmd" "-x!*.ps1" "-x!.svn" "$packageId.tar" "./*.*"
         foreach ($additionalIncludeDir in $additionalIncludeDirs)
         {
            sevenzip a -r -ttar "-x!*.cmd" "-x!*.ps1" "-x!.svn" "$packageId.tar" $additionalIncludeDir
         }
         write-host ""
         write-host "  Compressing Tarball Archive" -ForegroundColor $myheadlinecolor2
         sevenzip a "-tgzip" "$packageId.tar.gz" "$packageId.tar"
         
         if (test-path  "../tarballs/$packageId.tar")
         {
            del "../tarballs/$packageId.tar"
         }   
         move "$packageId.tar" "../tarballs/"         

    }
    else
    {
        write-host "package.xml not found!"
    }   
    
    write-host ""
    Write-Host "Package Created" -ForegroundColor $myheadlinecolor
    $Host.UI.RawUI.WindowTitle = "Generated Package: $packageId"
    pause
}

function Pause ($Message="Press any key to continue...")
{
    Write-Host -NoNewLine $Message
    try
    {
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {}
    Write-Host ""
}

generate-package