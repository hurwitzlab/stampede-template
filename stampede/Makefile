EMAIL = user@domain.com

clean:
	find . \( -name \*.conf -o -name \*.out -o -name \*.log -o -name \*.params -o -name launcher-\* \) -exec rm {} \;

foo:
	./00-controller.sh -e $(EMAIL) -r 01-foo.sh -p development -t "02:00:00" -a foo

update:
	apps-update -F app.json
