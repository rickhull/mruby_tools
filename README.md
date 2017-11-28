[![Build Status](https://travis-ci.org/rickhull/mruby_tools.svg?branch=master)](https://travis-ci.org/rickhull/mruby_tools)
[![Gem Version](https://badge.fury.io/rb/mruby_tools.svg)](https://badge.fury.io/rb/mruby_tools)
[![Dependency Status](https://gemnasium.com/rickhull/mruby_tools.svg)](https://gemnasium.com/rickhull/mruby_tools)
[![Security Status](https://hakiri.io/github/rickhull/mruby_tools/master.svg)](https://hakiri.io/github/rickhull/mruby_tools/master)

# mruby tools

This is a small gem that provides one tool at present: `mrbt`.  This is a
**ruby gem**, not an **mruby mgem**, but it is primarily useful for working
with **mruby**.

`mrbt` accepts any number of .rb files and "compiles" them into a standalone
executable using mruby.  The .rb files must be
[mruby-compatible](https://github.com/mruby/mruby/blob/master/doc/limitations.md) (roughly equivalent to MRI v1.9).

Two primary modes of operation are supported:

1. ruby code is injected into a C wrapper which is then compiled.  The ruby
code is **interpreted** every time the resulting binary is executed.

2. ruby code is first interpreted into **bytecode**, and the bytecode
is injected into a C wrapper which is then compiled.  This means a faster
runtime as the code interpretation is not performed at runtime.

## Install

### `git clone`

By using `git clone` rather than `gem install`, you can make use of rake
tasks, particularly for compiling mruby itself, a necessary prerequisite
for using `mrbt`.  This is the easiest way to get started if you are new
to mruby.  The mruby source is provided as a git submodule;
therefore you must `git clone --recursive` or else update the submodule
manually.

Prerequisites:

* `git`
* `rake`
* *build tools:* `gcc` `make` `bison` `ar`

```shell
git clone --recursive https://github.com/rickhull/mruby_tools.git
cd mruby_tools
rake hello_world
```

This will provide mruby source via a git repo submodule and then build it to
provide `libmruby.a`.

The rake command will proceed to "compiling" `examples/hello_world.rb` to
a standalone binary executable `examples/hello_world`, which will then be
executed with the customary output shown.

Once mruby has been built by rake, it will not be built again by rake as long
as `libmruby.a` is present.  The first run of `rake hello_world` takes up to
30 seconds or so, depending on your system.  The next run of
`rake hello_world` takes about a half-second, including compiling and
running the executable.

### *rubygems*

Only use this if you have an existing mruby built and installed.  `mrbt` will
be set up in your PATH, but you will have to specify the path to mruby
source via `-m path/to/mruby_dir` or `MRUBY_DIR` environment variable.  You
will not have (easy) access to rake tasks.

Prerequisites:

* *rubygems*
* *build tools:* `gcc` `make` `bison` `ar`
* *mruby_dir*
* *mruby_dir*/build/host/lib/libmruby.a

```shell
gem install mruby_tools
```

Now, `mrbt` may be used.  We set the `MRUBY_DIR` environment variable:

```shell
export MRUBY_DIR=~/src/mruby-1.3.0    # or wherever it lives
mrbt file1.rb file2.rb                # etc.
```

## Usage

```
  USAGE: mrbt file1.rb file2.rb ...
OPTIONS: -o outfile     (provide a name for the standalone executable)
         -c generated.c (leave the specified C file on the filesystem)
         -m mruby_dir   (provide the dir for mruby src)
         -b             (pregenerate ruby bytecode for faster execution)
         -v             (verbose)
```

With no additional options, `mrbt` will inject the contents of file1.rb and
file2.rb into C strings, to be loaded with mrb_load_nstring(), written to a
Tempfile.  `mrbt` then compiles the generated .c file using GCC and writes
a standalone executable (around 1.5 MB for "hello world").

### With `git clone` and `rake`

You can use `rake mrbt` to execute `bin/mrbt` with the proper load path, and
any arguments will be passed along. Some mrbt options conflict with rake
options.  You can prevent rake from parsing arguments by placing them
after ` -- `.

```shell
rake mrbt -- -h
rake mrbt examples/hello_world.rb
rake mrbt -- examples/hello_world.rb examples/goodbye_world.rb -o adios
```

Other useful rake tasks:

* hello world     - compiles and runs `examples/hello_world.rb`
* timed_simplex   - compiles and runs several files that work together
* raise_exception - compiles and runs `examples/raise.rb`
* examples - runs hello_world and timed_simplex
* verbose  - add verbose output, e.g. `rake verbose hello_world`
* bytecode - enable bytecode generation at compile time

## Examples

There are some example .rb files in examples/ that can be used to produce
an executable.  Use `mrbt` or `rake mrbt` as appropriate:

```shell
mrbt examples/hello_world.rb

# or
rake mrbt examples/hello_world.rb

# or even
rake hello_world
```

```
/home/vagrant/.rubies/ruby-2.4.0/bin/ruby -Ilib bin/mrbt examples/hello_world.rb -o examples/hello_world
compiling...
created binary executable: examples/hello_world
examples/hello_world
hello_world
```

The first line shows that rake is executing `mrbt` (via `ruby`), passing it
`examples/hello_world.rb` and naming the output executable
`examples/hello_world`.

`mrbt` outputs "compiling..." and then "created binary
executable: examples/hello_world"

Then `examples/hello_world` is executed, and it outputs "hello_world".

### Verbose Hello World

```shell
mrbt examples/hello_world.rb -v

# or
rake mrbt -- -v examples/hello_world.rb

# or even
rake verbose hello_world
```

```
/home/vagrant/.rubies/ruby-2.4.0/bin/ruby -Ilib bin/mrbt -v examples/hello_world.rb -o examples/hello_world
#include <stdlib.h>
#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/string.h>

void check_exc(mrb_state *mrb, char *filename) {
  if (mrb->exc) {
    mrb_value exc = mrb_obj_value(mrb->exc);
    mrb_value exc_msg = mrb_funcall(mrb, exc, "to_s", 0);
    fprintf(stderr, "ERROR in %s - %s: %s\n",
            filename,
            mrb_obj_classname(mrb, exc),
            mrb_str_to_cstr(mrb, exc_msg));
    /* mrb_print_backtrace(mrb);   # empty */
    exit(1);
  }
}

int
main(void)
{
  mrb_state *mrb = mrb_open();
  if (!mrb) {
    printf("mrb problem");
    exit(1);
  }

  /* examples/hello_world.rb */
  mrb_load_nstring(mrb, "puts :hello_world\n", 18);
  check_exc(mrb, "examples/hello_world.rb");

  mrb_close(mrb);
  return 0;
}

generated /tmp/mrbt-20171122-20650-4pi6tt.c
compiling...
created binary executable: examples/hello_world

file examples/hello_world
examples/hello_world: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=e9fb81e70686e761cf49202efc4f3e733d7aab17, not stripped

stat examples/hello_world
  File: ‘examples/hello_world’
  Size: 1631784         Blocks: 3192       IO Block: 4096   regular file
Device: 801h/2049d      Inode: 388542      Links: 1
Access: (0755/-rwxr-xr-x)  Uid: ( 1000/ vagrant)   Gid: ( 1000/ vagrant)
Access: 2017-11-22 23:42:12.202875568 +0000
Modify: 2017-11-22 23:42:12.190881566 +0000
Change: 2017-11-22 23:42:12.190881566 +0000
 Birth: -

examples/hello_world
hello_world
```

This proceeds exactly as before but with additional output:

* Show the generated C code
* Note the temporary file containing the C code
* Call `file` and `stat` on the output executable

### Verbose Bytecode Hello World

```shell
mrbt -v examples/hello_world.rb -b

# or
rake mrbt -- -b examples/hello_world.rb -v

# or even
rake verbose bytecode hello_world
```

```
/home/vagrant/.rubies/ruby-2.4.0/bin/ruby -Ilib bin/mrbt -b -v examples/hello_world.rb -o examples/hello_world
creating bytecode.mrb...
#include <stdlib.h>
#include <stdint.h>
#include <mruby.h>
#include <mruby/string.h>
#include <mruby/irep.h>

const uint8_t
#if defined __GNUC__
__attribute__((aligned(4)))
#elif defined _MSC_VER
__declspec(align(4))
#endif
/* bytecode.mrb */
test_symbol[] = {
0x52,0x49,0x54,0x45,0x30,0x30,0x30,0x34,0x22,0x80,0x00,0x00,0x00,0x65,0x4d,0x41,0x54,0x5a,0x30,0x30,0x30,0x30,0x49,0x52,0x45,0x50,0x00,0x00,0x00,0x47,0x30,0x30,0x30,0x30,0x00,0x00,0x00,0x3f,0x00,0x01,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x80,0x00,0x06,0x01,0x00,0x00,0x84,0x00,0x80,0x00,0xa0,0x00,0x00,0x00,0x4a,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00,0x04,0x70,0x75,0x74,0x73,0x00,0x00,0x0b,0x68,0x65,0x6c,0x6c,0x6f,0x5f,0x77,0x6f,0x72,0x6c,0x64,0x00,0x45,0x4e,0x44,0x00,0x00,0x00,0x00,0x08,
};

void check_exc(mrb_state *mrb) {
  if (mrb->exc) {
    mrb_value exc = mrb_obj_value(mrb->exc);
    mrb_value exc_msg = mrb_funcall(mrb, exc, "to_s", 0);
    fprintf(stderr, "ERROR %s: %s\n",
            mrb_obj_classname(mrb, exc),
            mrb_str_to_cstr(mrb, exc_msg));
    /* mrb_print_backtrace(mrb);   # empty */
    exit(1);
  }
}

int
main(void)
{
  mrb_state *mrb = mrb_open();
  if (!mrb) {
    printf("mrb problem");
    exit(1);
  }
  mrb_load_irep(mrb, test_symbol);
  check_exc(mrb);
  mrb_close(mrb);
  return 0;
}

generated /tmp/mrbt-20171122-25456-azsw3n.c
compiling...
created binary executable: examples/hello_world

file examples/hello_world
examples/hello_world: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=61e903e56a9e5d1159cb5a5ea4a669b05b493f44, not stripped

stat examples/hello_world
  File: ‘examples/hello_world’
  Size: 1324616   	Blocks: 2592       IO Block: 4096   regular file
Device: 801h/2049d	Inode: 388542      Links: 1
Access: (0755/-rwxr-xr-x)  Uid: ( 1000/ vagrant)   Gid: ( 1000/ vagrant)
Access: 2017-11-22 23:46:09.540147567 +0000
Modify: 2017-11-22 23:46:09.536149567 +0000
Change: 2017-11-22 23:46:09.536149567 +0000
 Birth: -

examples/hello_world
hello_world
```
