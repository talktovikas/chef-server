use_locked_config = $(wildcard USE_REBAR_LOCKED)
ifeq ($(use_locked_config),USE_REBAR_LOCKED)
  rebar_config = rebar.config.lock
else
  rebar_config = rebar.config
endif
REBAR = rebar -C $(rebar_config)

all: compile eunit dialyze

# Cleaning #####################################################################
clean:
	$(REBAR) clean

depclean:
	@echo "Deleting all dependencies"
	@rm -rf deps

relclean:
	@echo "Deleting rel/heimdall directory"
	@rm -rf rel/heimdall

allclean: depclean clean

distclean: relclean allclean

# Dependency Fetching ##########################################################

DEPS = $(CURDIR)/deps

$(DEPS):
	$(REBAR) get-deps

# Compilation ##################################################################
compile: $(DEPS)
	$(REBAR) compile

compile_app:
	$(REBAR) skip_deps=true compile

# Dialyzer #####################################################################

DIALYZER_OPTS = -Wrace_conditions -Wunderspecs

DIALYZER_DEPS = deps/epgsql/ebin \
		deps/epgsql/ebin \
		deps/lager/ebin \
		deps/mochiweb/ebin \
		deps/pooler/ebin \
		deps/sqerl/ebin \
		deps/webmachine/ebin

DEPS_PLT = heimdall.plt

ERLANG_DIALYZER_APPS = asn1 \
		       compiler \
		       crypto \
		       edoc \
		       edoc \
		       erts \
		       eunit \
		       eunit \
		       gs \
		       hipe \
		       inets \
		       kernel \
		       mnesia \
		       mnesia \
		       observer \
		       public_key \
		       runtime_tools \
		       runtime_tools \
		       ssl \
		       stdlib \
		       syntax_tools \
		       syntax_tools \
		       tools \
		       webtool \
		       xmerl


dialyze:
	dialyzer --src $(DIALYZER_OPTS) --plts ~/.dialyzer_plt $(DEPS_PLT) -r apps/heimdall/src -I deps

~/.dialyzer_plt:
	@echo "ERROR: Missing ~/.dialyzer_plt. Please wait while a new PLT is compiled."
	dialyzer --build_plt --apps $(ERLANG_DIALYZER_APPS)

# Testing ######################################################################

test: eunit

eunit: compile
	$(REBAR) eunit skip_deps=true

eunit_app: compile_app
	$(REBAR) eunit apps=heimdall skip_deps=true

# Release Creation #############################################################

rel: compile test rel/heimdall

rel/heimdall:
	@cd rel
	$(REBAR) generate
	@echo
	@echo ' __  __  ____ __ ___  ___ ____    ___  __    __   '
	@echo ' ||  || ||    || ||\\//|| || \\  // \\ ||    ||   '
	@echo ' ||==|| ||==  || || \/ || ||  )) ||=|| ||    ||   '
	@echo ' ||  || ||___ || ||    || ||_//  || || ||__| ||__|'
	@echo '                                                  '

#
# Unsure if we'll need these targets anymore...
#

# devrel: rel
#	@/bin/echo -n Symlinking deps and apps into release
#	@$(foreach lib,$(wildcard apps/* deps/*), /bin/echo -n .;rm -rf rel/heimdall/lib/$(shell basename $(lib))-* \
#	   && ln -sf $(abspath $(lib)) rel/heimdall/lib;)
#	@/bin/echo done.
#	@/bin/echo  Run \'make update\' to pick up changes in a running VM.

# update: compile
#	@cd rel/heimdall;bin/heimdall restart

# update_app: compile_app
#	@cd rel/heimdall;bin/heimdall restart


# Release Preparation ##########################################################

BUMP ?= patch
prepare_release: distclean unlocked_deps unlocked_compile update_locked_config rel
	@echo 'release prepared, bumping version'
	@$(REBAR) bump-rel-version version=$(BUMP)

unlocked_deps:
	@echo 'Fetching deps as: rebar -C rebar.config'
	@rebar -C rebar.config get-deps

# When running the prepare_release target, we have to ensure that a
# compile occurs using the unlocked rebar.config. If a dependency has
# been removed, then using the locked version that contains the stale
# dep will cause a compile error.
unlocked_compile:
	@rebar -C rebar.config compile

update_locked_config:
	@rebar lock-deps ignore=meck skip_deps=true
