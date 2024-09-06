
INIT_ENV_SCRIPT := ./oe-init-build-env
BITBAKE := bitbake

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
	$(BITBAKE) img-$(MACHINE)

# Clean the build directory (not recommended for large projects)
clean:
	@echo "Cleaning the Yocto build directory..."
	@if [ -z "$(MACHINE)" ]; then \
		echo ""; \
	else \
		$(BITBAKE) -c clean img-$(MACHINE); \
	fi


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

