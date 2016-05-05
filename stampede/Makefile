EMAIL = kyclark@email.arizona.edu

clean:
	find . \( -name \*.conf -o -name \*.out -o -name \*.log -o -name \*.params -o -name launcher-\* \) -exec rm {} \;

foo:
	./00-controller.sh -e $(EMAIL) -r 03-sna.sh -p development -t "02:00:00" -x 100000
