# Make a TWiki plugin zip package.
# Set TWIKIROOT to the root of the TWiki install.
# Set TWIKIPLUGINWEB to the TWiki web name that plugins are installed to.
# The topic files will be snarfed from there.
# Optionally set YourPlugin_EXTRAS to a list of extra files to be put
# in the package. These extra files must be available in the current dir.

%.zip:	%.zipdir
	cd $< ; zip -r ../$@ * -x CVS

%.zipdir:	%.pm $(notdir ${$*_EXTRAS})
	rm -rf $@
	mkdir $@
	mkdir -p $@/data/${TWIKIPLUGINWEB}
	mkdir -p $@/lib/TWiki/Plugins
	cp $*.pm $@/lib/TWiki/Plugins/
	cp ${TWIKIROOT}/data/${TWIKIPLUGINWEB}/$*.txt $@/data/${TWIKIPLUGINWEB}/
	cp ${TWIKIROOT}/data/${TWIKIPLUGINWEB}/$*.txt,v $@/data/${TWIKIPLUGINWEB}/
	for e in ${$*_EXTRAS}; do \
		mkdir -p $@/`dirname "$$e"`; \
		cp `basename "$$e"` $@/`dirname "$$e"`/; \
	done
	touch $@

clean:
	rm -rf *.zip *.zipdir
