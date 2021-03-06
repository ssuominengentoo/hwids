
ifeq "$(V)" "0"
  STATUS = git status -s
  Q=@
else
  STATUS = git status
  Q=
endif

ifeq "$(UDEV)" "yes"
  ALL_TARGETS=compress udev-hwdb
  INSTALL_TARGETS=install-base install-hwdb
else
  ALL_TARGETS=compress
  INSTALL_TARGETS=install-base
endif

all: $(ALL_TARGETS)

install: $(INSTALL_TARGETS)

fetch:
	$(Q)curl -z pci.ids -o pci.ids -R http://pci-ids.ucw.cz/v2.2/pci.ids
	$(Q)curl -z usb.ids -o usb.ids -R http://www.linux-usb.org/usb.ids
	$(Q)curl -z oui.txt -o oui.txt -R http://standards.ieee.org/develop/regauth/oui/oui.txt
	$(Q)curl -z iab.txt -o iab.txt -R http://standards.ieee.org/develop/regauth/iab/iab.txt
	$(Q)curl -z sdio.ids -o sdio.ids -R http://cgit.freedesktop.org/systemd/systemd/plain/hwdb/sdio.ids
	$(Q)curl -z udev/20-acpi-vendor.hwdb -o udev/20-acpi-vendor.hwdb -R http://cgit.freedesktop.org/systemd/systemd/plain/hwdb/20-acpi-vendor.hwdb
	$(Q)curl -z udev/20-bluetooth-vendor-product.hwdb -o udev/20-bluetooth-vendor-product.hwdb -R http://cgit.freedesktop.org/systemd/systemd/plain/hwdb/20-bluetooth-vendor-product.hwdb
	$(Q)curl -z udev/20-net-ifname.hwdb -o udev/20-net-ifname.hwdb -R http://cgit.freedesktop.org/systemd/systemd/plain/hwdb/20-net-ifname.hwdb
	$(Q)curl -z udev/60-keyboard.hwdb -o udev/60-keyboard.hwdb -R http://cgit.freedesktop.org/systemd/systemd/plain/hwdb/60-keyboard.hwdb
	$(Q)curl -z udev-hwdb-update.pl -o udev-hwdb-update.pl -R http://cgit.freedesktop.org/systemd/systemd/plain/hwdb/ids-update.pl
	$(Q)$(STATUS)

PV ?= $(shell ( awk '$$2 == "Date:" { print $$3; nextfile }' pci.ids usb.ids; git log --format=format:%ci -1 -- oui.txt udev/20-acpi-vendor.hwdb udev/20-bluetooth-vendor-product.hwdb udev/20-net-ifname.hwdb udev/60-keyboard.hwdb udev-hwdb-update.pl | cut -d ' ' -f1; ) | sort | tail -n 1 | tr -d -)
P = hwids-$(PV)

tag:
	git tag $(P)

udev-hwdb:
	perl ./udev-hwdb-update.pl && mv *.hwdb udev/

compress: pci.ids.gz usb.ids.gz

%.gz: %
	gzip -c $< > $@

MISCDIR=/usr/share/misc
HWDBDIR=$(shell pkg-config --variable=udevdir udev)/hwdb.d
DOCDIR=/usr/share/doc/hwids

install-base: compress
	mkdir -p $(DESTDIR)$(DOCDIR)
	install -p -m 644 README.md $(DESTDIR)$(DOCDIR)
	mkdir -p $(DESTDIR)$(MISCDIR)
	for file in usb.ids pci.ids usb.ids.gz pci.ids.gz oui.txt iab.txt; do \
		install -p -m 644 $$file $(DESTDIR)$(MISCDIR); \
	done

install-hwdb:
	mkdir -p $(DESTDIR)$(HWDBDIR)
	for file in udev/*.hwdb; do \
		install -p -m 644 $$file $(DESTDIR)$(HWDBDIR); \
	done
	udevadm hwdb --root $(DESTDIR) --update
