Sub Main()

	appPrefix$ = "roku/"
	urlPrefix$ = "http://192.168.0.124/applicazioni_git/" + appPrefix$
	urlPrefixUpdate$ = "http://192.168.0.124/applicazioni_git/"
	manifest$ = "manifest.mf"
	' End custom variables

	' These should be custom variables but currently are not
	htmlFile$ = "index.html"
	' Default to updating every 30 secs
	updateIntervalInSeconds = 30

	htmlWidget = DownloadAssetsAndCreateHtmlWidget(urlPrefix$, manifest$, htmlFile$)
	mp = CreateObject("roMessagePort")
	udp = CreateObject("roDatagramReceiver", 5000)
	udp.SetPort(mp)
	udp.SetUserData("port 5000")

	device = CreateObject("roDeviceInfo")
	deviceId = device.GetDeviceUniqueId()

	sender = CreateObject("roDatagramSender")
	sender.setDestination("192.168.0.124", 5000)
	sender.Send("connected")

	' mi arriva in UDP un messaggio o di comando o di cambio pagina

	while true
	  	event = mp.WaitMessage(0)
			if type(event) = "roDatagramEvent" then
				msg = event.GetString()
				typeOfMessage = left(msg, 4)
				shortMsg = mid(msg, 5)

				print typeOfMessage
				print shortMsg

				if typeOfMessage = "com/" then
					if shortMsg = "reboot" then
						print "reboot " + event.GetString()
						RebootSystem()
					else if shortMsg = "refresh" then
						htmlWidget = DownloadAssetsAndCreateHtmlWidget(urlPrefixUpdate$ + appPrefix$, manifest$, htmlFile$)
					end if
				else if typeOfMessage = "url/" then
					appPrefix$ = shortMsg
					print "altro comando " + appPrefix$
					htmlWidget = DownloadAssetsAndCreateHtmlWidget(urlPrefixUpdate$ + appPrefix$, manifest$, htmlFile$)
				end if
      		end if
	end while

    StartTelnet()
End Sub

Function EnableSSH()
	reg = CreateObject("roRegistrySection", "networking")
	reg.write("ssh", 22)
	n=CreateObject("roNetworkConfiguration", 0)
	n.SetLoginPassword("password")
	n.Apply()
	RebootSystem()
End Function

Function StartTelnet()
	'set setTelnetON to true to enable Telnet or false to disable Telnet
	'added Enable DWS
	setTelnetON = true
	debug = true
	
	systemLog = CreateObject("roSystemLog")
	
	print "Running Telnet activation/disactivation script ... "
	
	systemLog.SendLine("Running Telnet activation/disactivation script ... ")
	
	if type(vm) <> "roVideoMode" then 
		vm = CreateObject("roVideoMode")
	end if	
	
	meta99 = CreateObject("roAssociativeArray")
	meta99.AddReplace("CharWidth", 30)
	meta99.AddReplace("CharHeight", 50)
	meta99.AddReplace("BackgroundColor", &H101010) ' Dark grey
	meta99.AddReplace("TextColor", &Hffff00) ' Yellow
	tf99 = CreateObject("roTextField", vm.GetSafeX()+10, vm.GetSafeY()+vm.GetSafeHeight()/2, 60, 2, meta99)

	tf99.SendBlock("Checking Telnet Registry settings.")
	systemLog.SendLine("Checking Telnet Registry settings.")
	sleep(2000)
	tf99.Cls()
	
	if type(registrySection) <> "roRegistrySection" then 
		registrySection = CreateObject("roRegistrySection", "networking")
	end if
	
	
	if type(registrySectionDebug) <> "roRegistrySection" then 
		registrySectionDebug = CreateObject("roRegistrySection", "brightscript")
	end if		
	
	'IsTelnetON = registrySection.Exists("telnet")
	
	TelnetInRegistry = 	registrySection.Read("telnet")
	
	if setTelnetON then
	
		if TelnetInRegistry <> "" then 
				
			tf99.SendBlock("Telnet Already set on Port " + TelnetInRegistry )
			systemLog.SendLine("Telnet Already set")
			sleep(40000)
			
		else 
		
			TelnetKeyWritten = registrySection.Write("telnet", "23")
			DebugKeyWritten = registrySectionDebug.Write("debug", "1")
			
			Print " **********  Debug Key Written  ************** "
			
			systemLog.SendLine(" ***** Telnet and Debug Mode Enabled ***** ")
			
			' write web server enable
			registrySection.Write("http_server", "80")
			registrySection.flush()
			
			
		
			
			
			if TelnetKeyWritten then
				tf99.SendBlock("Telnet Successfully set, Please Reboot the player without this script")
				systemLog.SendLine("Telnet Successfully set, Please Reboot the player without this script")
				registrySection=invalid
				sleep(40000)
				'RebootSystem()		
			else
				tf99.SendBlock("Unable to set Telnet")
				systemLog.SendLine("Unable to set Telnet")
				sleep(40000)
			end if 
			
		end if
		
	else
	
		if TelnetInRegistry <> "" then
			TelnetKeyWritten = registrySection.Write("telnet", "")
			DebugKeyWritten = registrySectionDebug.Write("debug", "")
			' write web server enable
			registrySection.Write("http_server", "80")
			registrySection.flush()
			registrySection=invalid
			
			if TelnetKeyWritten then
				tf99.SendBlock("Telnet Successfully set, Please Reboot the player without this script")
				systemLog.SendLine("Telnet Successfully set, Please Reboot the player without this script")
				sleep(40000)
				'RebootSystem()	
			else
				tf99.SendBlock("Unable to Disabled Telnet")
				systemLog.SendLine("Unable to Disabled Telnet")
				sleep(40000)
			end if 
			
		else 
			tf99.SendBlock("Telnet Already Disabled !!! ")
			systemLog.SendLine("Telnet Already Disabled !!!")
			sleep(40000)
		end if
	
	end if
	
	'stop
End Function

'''''''''''''''''''''''''''
Sub AddFile(spec as Object, name as String, link as String)
	spec.s = spec.s + "  <download>" + chr(13) + chr(10)
	spec.s = spec.s + "   <name>" + name + "</name>" + chr(13) + chr(10)
	spec.s = spec.s + "   <link>" + link.GetEntityEncode() + "</link>" + chr(13) + chr(10)
	spec.s = spec.s + "   <change_hint>" + Str(UpTime(0)) + "</change_hint>" + chr(13) + chr(10)
	spec.s = spec.s + "  </download>" + chr(13) + chr(10)
	spec.file_count = spec.file_count + 1
End Sub
'''''''''''''''''''''''''''
Function BeginSpec()
	s = ""
	s = s + "<?xml version=" + chr(34) + "1.0" + chr(34) + " encoding=" + chr(34) + "UTF-8" + chr(34) + "?>" + Chr(13) + Chr(10)
	s = s + "<sync name=" + chr(34) + "Friendly name" + chr(34) + " version=" + chr(34) + "1.0" + chr(34) + ">" + chr(13) + chr(10)
	s = s + " <files>" + chr(13) + chr(10)

	spec = {}
	spec.s = s
	spec.file_count = 0
	return spec
End Function
'''''''''''''''''''''''''''
Sub EndSpec(spec as Object)
	spec.s = spec.s + " </files>" + chr(13) + chr(10)
	spec.s = spec.s + "</sync>" + chr(13) + chr(10)
	WriteAsciiFile("syncspec.xml", spec.s)
End Sub
'''''''''''''''''''''''''''
Function DownloadAssets(spec as Object, config as Object)
    POOL_EVENT_FILE_DOWNLOADED = 1
    POOL_EVENT_FILE_FAILED = -1
    POOL_EVENT_ALL_DOWNLOADED = 2
    POOL_EVENT_ALL_FAILED = -2
    
    sync_spec = CreateObject("roSyncSpec")
    if not sync_spec.ReadFromString(spec.s) then
	stop
    end if

    assetCollection = sync_spec.GetAssets("download")

    CreateDirectory("pool")

    pool = CreateObject("roAssetPool", "pool")
    if type(pool) <> "roAssetPool" then
	stop
    end if

    fetcher = CreateObject("roAssetFetcher", pool)
    if type(fetcher) <> "roAssetFetcher" then
	stop
    end if

    pool.ReserveMegabytes(1)
    fetcher.SetFileRetryCount(2)
    if not fetcher.SetFileProgressIntervalSeconds(1) then
	stop
    end if

    if config.relative_link_prefix <> invalid then
	fetcher.SetRelativeLinkPrefix(config.relative_link_prefix)
    end if

    if config.max_pool_size <> invalid then
	if not pool.SetMaximumPoolSizeMegabytes(config.max_pool_size) then
	    print pool.GetFailureReason()
	    stop
	end if
    end if
    
    mp = CreateObject("roMessagePort")
    fetcher.SetPort(mp)
    
    files_downloaded = 0
    complete = false

   	if not fetcher.AsyncDownload(assetCollection) then
	    print "AsyncDownload failed: "; pool.GetFailureReason()
	    stop
	end if

    while not complete
	ev = wait(0, mp)
	if type(ev) = "roAssetFetcherEvent" then
	    if ev.GetEvent() = POOL_EVENT_FILE_DOWNLOADED then
			print "File: "; ev.GetName(); " downloaded "; ev.GetResponseCode()
			files_downloaded = files_downloaded + 1
	    else if ev.GetEvent() = POOL_EVENT_FILE_FAILED then
	        if not config["expect_fail_" + ev.GetName()] <> invalid then
		    	print "File: "; ev.GetName(); " failed "; ev.GetResponseCode(); " "; ev.GetFailureReason()
		    	stop
			end if
	    else if ev.GetEvent() = POOL_EVENT_ALL_DOWNLOADED then
	        print "Pool download reported complete"
			complete = true
	    else if ev.GetEvent() = POOL_EVENT_ALL_FAILED then
		    print "Pool download failed"
		    stop
	    else
	        print "Unknown event code"
			stop
	    end if
	else if type(ev) = "roAssetFetcherProgressEvent" then
	    print "Progress: "; ev.GetFileIndex()+1; "/"; ev.GetFileCount(); " "; ev.GetFileName()
	else
	    print "Unknown event: "; type(ev)
	    stop
	end if
    endwhile

    if config.download_count <> invalid then
		expected_download_count = config.download_count
    else
        expected_download_count = spec.file_count
    end if
	
    if files_downloaded <> expected_download_count then 
		print files_downloaded
		print expected_download_count
	stop
    end if
	
    ret = CreateObject("roAssociativeArray")
    ret.pool = pool
    ret.assetCollection = assetCollection 
    return ret

End Function
'''''''''''''''''''''''''''
Function CreateHtmlWidget(assetObjects as Object, htmlFile$ as String)

    vm=CreateObject("roVideoMode")
    width=vm.GetResX()
    height=vm.GetResY()
    rect=CreateObject("roRectangle", 0, 0, width, height)

	url$ = "file:///" + htmlFile$
	is = { port: 2999 }
	config = {
    	nodejs_enabled: true
    	inspector_server: is
    	brightsign_js_objects_enabled: true
      url: url$
	}

	htmlWidget = CreateObject("roHtmlWidget", rect, config)
	htmlWidget.EnableSecurity(false)
	htmlWidget.EnableJavascript(true)
	prefix$ = ""
	htmlWidget.MapFilesFromAssetPool(assetObjects.pool, assetObjects.assetCollection, prefix$, "/")
	htmlWidget.SetUrl(url$)
    jsClasses = CreateObject("roAssociativeArray")
    jsClasses["*"] = [ "*" ]
    htmlWidget.AllowJavaScriptUrls(jsClasses)
	return htmlWidget

End Function
'''''''''''''''''''''''''''
Function CreateSpecAndDownloadAssets(urlPrefix$ as String, manifest$ as String, htmlFile$ as String)

	DeleteFile("manifest.mf")

	u=CreateObject("roUrlTransfer")

	u.SetUrl(urlPrefix$+manifest$)
	result = u.GetToFile("manifest.mf")
	if result <> 200 then
		assetObjects = GetAssetsFromDisk()
		return assetObjects 
	endif

	manifestFileAsString$ = ReadAsciiFile("manifest.mf")

	r = CreateObject( "roRegex", "$", "m" )
	files = r.Split( manifestFileAsString$ )

	spec = BeginSpec()

	for each file in files
	    f = file.Trim()
	    if len(f)>1
		    ignore = left(f,5)="CACHE" or left(f,1)="#" or left(f,7)="NETWORK"
	   		if not(ignore)
				AddFile(spec, f, urlPrefix$+f)
			endif
		endif
	next

	EndSpec(spec)

	assetObjects = DownloadAssets(spec, {})
	return assetObjects

End Function
'''''''''''''''''''''''''''
Function GetAssetsFromDisk()
	' Couldn't get manifest; see if the sync spec is on disk
	sync_spec = CreateObject("roSyncSpec")
	if not sync_spec.ReadFromFile("syncspec.xml") then
		print "Network error; no sync spec on disk"
		return invalid
	end if
	assetCollection = sync_spec.GetAssets("download")
	pool = CreateObject("roAssetPool", "pool")
	if type(pool) <> "roAssetPool" then
		print "Network error; no sync spec on disk"
		return invalid
	end if
	ret = CreateObject("roAssociativeArray")
	ret.pool = pool
	ret.assetCollection = assetCollection 
	print "Network error; found sync spec on disk"
	return ret
End Function
'''''''''''''''''''''''''''
Function DownloadAssetsAndCreateHtmlWidget(urlPrefix$ as String, manifest$ as String, htmlFile$ as String)

	assetObjects = CreateSpecAndDownloadAssets(urlPrefix$, manifest$, htmlFile$)
	if (assetObjects <> invalid)
		htmlWidget = CreateHtmlWidget(assetObjects, htmlFile$)
		htmlWidget.Show()
		return htmlWidget
	else
		print "Couldn't retrieve assets from network or disk. Please repair network connection and try again."
		return invalid
	endif

End Function
