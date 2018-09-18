.PHONY: all clean run

all: priv static

priv:
	mkdir -p priv

static: priv/
	ln -fs ../static priv/

clean:
	$(RM) -r priv

run:
	mix scenic.run
