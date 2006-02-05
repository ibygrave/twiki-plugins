all:	ExitPlugin.zip

%.zip:	%.zipdir
	cd $< ; zip -r ../$@ * -x CVS

ExitPlugin.zipdir:	exit.cgi ExitPlugin.pm
	mkdir $@
	mkdir -p $@/data/TWiki
	mkdir -p $@/lib/TWiki/Plugins
	mkdir -p $@/pub/TWiki/ExitPlugin
	cp ExitPlugin.pm $@/lib/TWiki/Plugins/
	cp exit.cgi $@/pub/TWiki/ExitPlugin/
	cp /var/lib/twiki/data/TWiki/ExitPlugin.txt* $@/data/TWiki/

clean:
	rm -rf *.zip *.zipdir
