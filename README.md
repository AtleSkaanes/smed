# SMED

> A small web framework using luau

`smed` comes both in the form of a library, and an executable

## Library

### Installation

Simply fetch the library in your project

```sh
$ zig fetch --save git+https://github.com/AtleSkaanes/smed
```

And then add the `libsmed` module to your `build.zig` file

```zig
const smed = b.dependency("smed", .{});
exe.root_module.addImport("libsmed", smed.module("libsmed"));
```

### Usage

Here is a small program using `libsmed`, which evaluates a `"index.html"` file, and prints the output to stdout

```zig
const smedlib = import("libsmed");

fn main() !void {
    const allocator = std.heap.smp_allocator;

    var smed = try libsmed.Smed.init(allocator);
    defer smed.deinit();

    // Adds `Smed.foo.bar` to the lua stack
    try smed.addGlobal(.{ .bar = "baz" }, "foo");

    const out = try smed.evalFile("index.html");
    defer allocator.free(out);

    std.debug.print("{s}", out);
}
```

## Executable

### Installation

To install the executable, clone the repo

```sh
$ git clone https://github.com/AtleSkaanes/smed
$ cd smed
```

and compile manually

```sh
$ zig build --release=fast
```

### Usage

Simply call `smed` executable, and give the path to the smed file to evaluate

```sh
$ ./zerv ./path/to/file
```

This will print the evaluated file to stdout, use the `-o` flag if you want it to output to a file instead
