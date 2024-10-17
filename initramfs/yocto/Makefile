
INIT_ENV_SCRIPT := ./oe-init-build-env
BITBAKE := bitbake

MACHINE ?= sp7350
BOARDNAME ?= ev

OEROOT := $(CURDIR)
export OEROOT

BITBAKEDIR := $(OEROOT)/bitbake
BBPATH := $(OEROOT)/$(MACHINE)_build
export BBPATH

PYTHONPATH := $(BITBAKEDIR)/lib
export PYTHONPATH

BUILDDIR := $(OEROOT)/$(MACHINE)_build
export BUILDDIR

export PATH := $(PATH):$(OEROOT)/scripts:$(OEROOT)/bitbake/bin

BB_ENV_PASSTHROUGH_ADDITIONS := 'ALL_PROXY BBPATH_EXTRA BB_LOGCONFIG BB_NO_NETWORK BB_NUMBER_THREADS BB_SETSCENE_ENFORCE BB_SRCREV_POLICY DISTRO FTPS_PROXY FTP_PROXY GIT_PROXY_COMMAND HTTPS_PROXY HTTP_PROXY MACHINE NO_PROXY PARALLEL_MAKE SCREENDIR SDKMACHINE SOCKS5_PASSWD SOCKS5_USER SSH_AGENT_PID SSH_AUTH_SOCK STAMPS_DIR TCLIBC TCMODE all_proxy ftp_proxy ftps_proxy http_proxy https_proxy no_proxy '
export BB_ENV_PASSTHROUGH_ADDITIONS

.PHONY: all build clean cleanall help

all: build

# Build the Yocto image
check:
	@echo "MACHINE = \"$(MACHINE)\"" > $(MACHINE)_build/conf/local.conf
	@echo "DISTRO = \"v1\"" >> $(MACHINE)_build/conf/local.conf
	@echo "REPRODUCIBLE_PATHS = \"1\"" >> $(MACHINE)_build/conf/local.conf
	@echo "BOARDNAME = \"$(BOARDNAME)\"" >> $(MACHINE)_build/conf/local.conf

build: check 
	@echo "Building the Yocto image $(MACHINE) ..."
	@if [ -f rootfs.tar.bz2 ] ; then rm rootfs.tar.bz2; fi
	@./check_modified.sh; \
	if [ $$? -ne 0 ]; then \
		set -e; \
		if [ -z "$(MACHINE)" ]; then \
			echo ""; \
		else \
			$(BITBAKE) -c clean img-$(MACHINE); \
		fi; \
		rm -rf ../disk; \
		$(BITBAKE) img-$(MACHINE); \
		if [ $$? -ne 0 ]; then \
			exit 1; \
		fi; \
		mv `cat rootfs_path`/rootfs ../disk; \
		mkdir -p ../disk/usr/lib/fonts; \
		cp files/* ../disk/usr/lib/fonts; \
		mv bbfile.md5.0 bbfile.md5; \
	fi

# Clean the build directory (not recommended for large projects)
clean: check
	$(BITBAKE) -c cleansstate $(IMAGE);

# Clean everything (use with caution)
cleanall:
	@echo "Cleaning all build files..."
	@if [ -z "$(MACHINE)" ]; then \
		echo ""; \
	else \
		cd $(MACHINE)_build; \
		rm bitbake*; \
		rm -rf cache/ downloads/ sstate-cache/ tmp-glibc/ tmp/ conf/conf-notes.txt conf/templateconf.cfg
	fi

