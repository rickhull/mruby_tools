[![Build Status](https://travis-ci.org/rickhull/mruby_tools.svg?branch=master)](https://travis-ci.org/rickhull/mruby_tools)
[![Gem Version](https://badge.fury.io/rb/mruby_tools.svg)](https://badge.fury.io/rb/mruby_tools)
[![Dependency Status](https://gemnasium.com/rickhull/mruby_tools.svg)](https://gemnasium.com/rickhull/mruby_tools)
[![Security Status](https://hakiri.io/github/rickhull/mruby_tools/master.svg)](https://hakiri.io/github/rickhull/mruby_tools/master)

# mruby tools

This is a small gem that provides one tool at present: `mrbt`

`mrbt` accepts any number of .rb files and "compiles" them into a standalone
executable using mruby.  The .rb files must be
[mruby-compatible](https://github.com/mruby/mruby/blob/master/doc/limitations.md) (roughly equivalent to MRI v1.9).

## Install

### `git clone`

By using `git clone` rather than `gem install`, you can make use of rake
tasks, particularly for compiling mruby itself, a necessary prerequisite
for using `mrbt`.  This is the easiest way to get started if you are new
to mruby.  The mruby source is provided as a git submodule;
therefore you must `git clone --recursive` or else update the submodule
manually.

Prerequisites:

* git
* rake
* build tools: gcc, make, bison, ar

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
as `libmruby.a` is present.

### *rubygems*

Only use this if you have an existing mruby built and installed.  `mrbt` will
be set up in your PATH, but you will have to specify the path to mruby
source via `-m path/to/mruby_dir` or `MRUBY_DIR` environment variable.  You
will not have (easy) access to rake tasks.

Prerequisites:

* rubygems
* build tools: gcc, make, bison, ar
* mruby_dir
* mruby_dir/build/host/lib/libmruby.a

```shell
gem install mruby_tools
```

Now, `mrbt` may be used.  It will need to know where to find the mruby_dir,
so specify it with the `-m` flag or `MRUBY_DIR` environment variable.

```shell
export MRUBY_DIR=~/src/mruby-1.3.0    # or wherever
mrbt file1.rb file2.rb                # etc.
```

## Usage

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

* hello world - compiles and runs `examples/hello_world.rb`
* timed_simplex - compiles and runs several files that work together
* raise_exception - compiles and runs `examples/raise.rb`
* examples - runs hello_world and timed_simplex
* verbose - add verbose output, e.g. `rake verbose hello_world`

### With *rubygems*

```shell
mrbt -h
```

```
  USAGE: mrbt file1.rb file2.rb ...
OPTIONS: -o outfile     (provide a name for the standalone executable)
         -c generated.c (leave the specified C file on the filesystem)
         -m mruby_dir   (provide the dir for mruby src)
         -v             (verbose)
```

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
/home/vagrant/.rubies/ruby-2.4.0/bin/ruby -Ilib bin/mrbt examples/hello_world.rb -o examples/hello_world -v
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

generated /tmp/mrbt-20171117-24568-no7ee3.c
compiling...
created binary executable: examples/hello_world

file examples/hello_world
examples/hello_world: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=2114ab60983156c92a5a74b88895f9c43a4bb086, not stripped

stat examples/hello_world
  File: ‘examples/hello_world’
    Size: 1559056         Blocks: 3048       IO Block: 4096   regular file
Device: 801h/2049d      Inode: 388049      Links: 1
Access: (0755/-rwxr-xr-x)  Uid: ( 1000/ vagrant)   Gid: ( 1000/ vagrant)
Access: 2017-11-17 18:48:25.713629203 +0000
Modify: 2017-11-17 18:48:25.709629203 +0000
Change: 2017-11-17 18:48:25.709629203 +0000
 Birth: -

examples/hello_world
hello_world
```

This proceeds exactly as before but with additional output:

* Show the generated C code
* Note the temporary file containing the C code
* Call `file` and `stat` on the output executable
