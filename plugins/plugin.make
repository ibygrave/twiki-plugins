# Make a TWiki plugin zip package.
# Set TWIKIROOT to the root of the TWiki install.
# Set TWIKIPLUGINWEB to the TWiki web name that plugins are installed to.
# The topic files will be snarfed from there.
# Optionally set YourPlugin_EXTRAS to a list of extra files to be put
# in the package. These extra files must be available in the current dir.
# Optionally set YourPlugin_EXTRA_PAGES to a list of extra twiki pages
# to be put in the package. Pages must be given in the form "Web/Topic".

%.zip:	%.zipdir
	cd $< ; zip -r ../$@ * -x CVS -x .svn

%.zipdir: EXTRAS=${$*_EXTRAS}
%.zipdir: EXTRAS_SRC=$(notdir ${EXTRAS})
%.zipdir: PAGES=${TWIKIPLUGINWEB}/$* ${$*_EXTRA_PAGES}
%.zipdir:	%.pm ${EXTRAS_SRC}
	rm -rf $@
	mkdir $@
	touch $@/$*.version
	mkdir -p $@/lib/TWiki/Plugins
	cp $*.pm $@/lib/TWiki/Plugins/
	svn info $*.pm >>$@/$*.version; \
	set -ex; for p in ${PAGES}; do \
		mkdir -p $@/data/`dirname "$$p"`; \
		cp ${TWIKIROOT}/data/$$p.txt $@/data/$$p.txt; \
		cp ${TWIKIROOT}/data/$$p.txt,v $@/data/$$p.txt,v; \
	done
	set -ex; for e in ${EXTRAS}; do \
		mkdir -p $@/`dirname "$$e"`; \
		cp `basename "$$e"` $@/`dirname "$$e"`/; \
		svn info `basename "$$e"` >>$@/$*.version; \
	done
	touch $@

clean:
	rm -rf *.zip *.zipdir
