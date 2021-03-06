@prompt $
@set path=%path%;"c:\Program Files\7-Zip"
@set plugin_name=me.songbook.test
@set plugin_source=../../wcf/lib/acp/package/plugin
@cls
@echo Make WCF Plugin Package


@echo deleting old archives
@echo -----------
del *.tar /Q
del *.gz /Q

@echo generating new archives
@echo -----------
cd optionals
7z a -r -ttar ../optionals.tar ./*
cd ..
7z a -ttar -x!*.cmd %plugin_name%.tar ./*.*
7z a -r -ttar %plugin_name%.tar ./*/*.tar

7z a -tgzip %plugin_name%.tar.gz %plugin_name%.tar
pause