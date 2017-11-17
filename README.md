[![Build Status](https://travis-ci.org/rickhull/mruby-tools.svg?branch=master)](https://travis-ci.org/rickhull/mruby-tools)
[![Gem Version](https://badge.fury.io/rb/mruby_tools.svg)](https://badge.fury.io/rb/mruby_tools)
[![Dependency Status](https://gemnasium.com/rickhull/mruby-tools.svg)](https://gemnasium.com/rickhull/mruby-tools)
[![Security Status](https://hakiri.io/github/rickhull/mruby-tools/master.svg)](https://hakiri.io/github/rickhull/mruby-tools/master)

# MRuby Tools

This is a small gem that provides one tool: `mrbt`

`mrbt` accepts any number of .rb files and "compiles" them into a standalone
executable using mruby.  The .rb files must be mruby-compatible (roughly
equivalent to MRI v1.9).

## Install

Prerequisites:

* gcc
* MRuby source downloaded
* mruby/build/host/lib/libmruby.a built

```
$ gem install mruby_tools
```

## Usage

```
$ export MRUBY_SRC=~/src/mruby-1.3.0    # or wherever
$ mrbt file1.rb file2.rb                # etc.
```

With no additional options, `mrbt` will inject the contents of file1.rb and
file2.rb into C strings, to be loaded with mrb_load_nstring(), written to a
Tempfile.  `mrbt` then compiles the generated .c file using GCC and writes
a standalone executable (around 1.5 MB for "hello world").

## Examples

There are some example .rb files in examples/ that can be used to produce
an executable.  Rake tasks make this easy:

```
$ rake hello_world

/home/vagrant/.rubies/ruby-2.4.0/bin/ruby -Ilib bin/mrbt examples/hello_world.rb -o examples/hello_world
compiling...
created binary executable: examples/hello_world
examples/hello_world
hello_world
```

The first line below the prompt shows that rake is executing `mrbt`, passing it
`examples/hello_world.rb` and naming the output executable
`examples/hello_world`.

`mrbt` outputs "compiling..." and then "created binary
executable: examples/hello_world"

Then `examples/hello_world` is executed, and it outputs "hello_world".

```
$ rake verbose hello_world

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
