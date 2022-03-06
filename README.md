# Cython extension module for ``geographiclib``

## TL;DR

Pythonic [`geographiclib` package](https://pypi.python.org/pypi/geographiclib) reimplements geodesic math in Python. Using Cython bindings for C++ version of `geographiclib` allows for **60-90x** speedup for geodesic functions.

**Warning:** only `Inverse()`, `Direct()`, and `InverseLine()` for `Geodesic.WGS84` are implemented. For `GeodesicLine`, only `Position()` is implemented.
For `Rhumb.WGS84`, `Direct()`, `Inverse()`, `Line()`, and `InverseLine()` are implemented. For `RhumbLine`, `Position()` is implemented, as well as an extra method `Positions()` as an efficient workaround to Cython limitations.

```bash
# for Ubuntu
sudo apt-get install -y libgeographic-dev
# for macOS:
brew install geographiclib

# and then:
pip install geographiclib-cython-bindings
```

For instructions on how to build and distribute, read on.

## Prerequisites

The following instructions are tested for Ubuntu 16.04, Amazon Linux, and macOS Sierra 10.12.

You will need the C++ `geographiclib` library (for compile-time and for run-time, too).

- Option 1 (recommended for Ubuntu and macOS): Install `libgeographic-dev` package, however it looks like the built-from-sources version is fresher.

  Ubuntu:
    ```bash
    sudo apt-get install -y libgeographic-dev
    ```
  macOS:
    ```bash
    brew install geographiclib
    ```

- Option 2 (recommended for Ubuntu and Amazon Linux): Compile and install it from sources.
  This creates bunch of `*.hpp` in `/usr/local/include/GeographicLib/` and `/usr/local/lib/libGeographic.so`:
    ```bash
    git clone --depth=1 git://git.code.sourceforge.net/p/geographiclib/code geographiclib

    cd geographiclib
    mkdir BUILD
    cd BUILD

    cmake ..
    make
    sudo make install
    ```
  See [installation manual](https://geographiclib.sourceforge.io/html/install.html) in case of problems.

For development, you will also need Cython:
```bash
pip install cython
```

## Description

There are two Cython files: `cgeographiclib.pxd` describing the C++ API of the `libGeographic` library, and `geographiclib_cython.pyx` describing classes that will be visible from Python user code. 
The `.pyx` imports `.pxd` to learn about C++ classes and functions available to be called.
An additional file `cython_extern_src/rhumb_line_positions.cpp` contains C++ code that is directly included in the `.pyx` file.

We wrap C++ classes `Geodesic` and `GeodesicLine` into Cython classes `PyGeodesic` and `PyGeodesicLine`. 
Additionally, we define a pure Python class `Geodesic` with a single field `WGS84` to mimic the behavior of the official `geographiclib` package.

Similarly, we wrap C++ classes `Rhumb` and `RhumbLine` into Cython classes `PyRhumb` and `PyRhumbLine`. (Note: Due to limitations in Cython, the `PyRhumbLine` class is not able to directly wrap the C++ `RhumbLine`, so a workaround is used.) We also define a pure Python class `Rhumb` with a single field `WGS84` to mimic the behavior of the official `geographiclib` package.

There is also `setup.py` file. 
This file describes how to build the extension module, using `distutils`.
In there, we specify the library to link with as `libraries=['Geographic']`. The `Geographic` stands for `libGeographic.so` that we previously installed.

There are two options to build the package:
- One, use Cython's `cythonize()` function to generate a `.cpp` file from the `.pyx` one, and then compile it against the `libGeographic.so` library.
- Two, if the `.cpp` is already provided, just compile it - no Cython required!

## Development build

For development, use option 1 by providing `--cython` flag:

```bash
python setup.py build_ext --inplace --cython
```

The result will be a `.so` shared library named like `geographiclib_cython.cpython-35m-x86_64-linux-gnu.so`. 
`build_ext` means we're building a C++ extension. `--inplace` means to put it in the current directory.
If you run `python` from current directory, you'll be able to `import geographiclib_cython`.

## Distribute

To distribute, call `sdist` with `--cython` flag to create source distribution (unbuilt):

```bash
python setup.py sdist --cython
```

The result will be a `dist/` directory with a distribution named like `geographiclib-cython-bindings-1.0.0.tar.gz` inside.
The archive contains `setup.py` and `geographiclib_cython.cpp`, so users can build and install it without having Cython!

To publish to PyPI, run:

```bash
twine upload -r pypi dist/*
```

## Install

To install, locate the `.tar.gz` distribution and run:
```bash
pip install geographiclib-cython-bindings-1.0.0.tar.gz
```

For conda, you might need to activate your environment first:

```bash
$ which pip
/home/vagrant/.local/bin/pip

$ source activate root

(root) $ which pip
/home/vagrant/anaconda3/bin/pip
```

## Usage

Let's try to import and use it!

```bash
$ ipython
Python 3.5.2 |Anaconda custom (64-bit)| (default, Jul  2 2016, 17:53:06)
Type 'copyright', 'credits' or 'license' for more information
IPython 6.0.0 -- An enhanced Interactive Python. Type '?' for help.

In [1]: from geographiclib_cython import Geodesic

In [2]: Geodesic.WGS84.Inverse(10, 20, 30, 40)
Out[2]:
{'azi1': 40.319640222045905,
 'azi2': 47.328994793150066,
 'lat1': 10.0,
 'lat2': 30.0,
 'lon1': 20.0,
 'lon2': 40.0,
 's12': 3035728.956905633}

In [3]: Geodesic.WGS84.Direct(10, 20, 40.319640222045905, 3035728.956905633)
Out[3]:
{'azi1': 40.319640222045905,
 'azi2': 47.328994793150066,
 'lat1': 10.0,
 'lat2': 29.999999999999996,
 'lon1': 20.0,
 'lon2': 40.00000000000001,
 's12': 3035728.956905633}
```

## Speedup

```python
>>> import timeit
>>> timeit.timeit('Geodesic.WGS84.Inverse(10, 20, 30, 40)', setup='from geographiclib.geodesic import Geodesic', number=10000)
1.7752603970002383
>>> timeit.timeit('Geodesic.WGS84.Inverse(10, 20, 30, 40)', setup='from geographiclib_cython import Geodesic', number=10000)
0.024111284990794957
>>> timeit.timeit('Geodesic.WGS84.Direct(10, 20, 30, 40000)', setup='from geographiclib.geodesic import Geodesic', number=100000)
7.022558598022442
>>> timeit.timeit('Geodesic.WGS84.Direct(10, 20, 30, 40000)', setup='from geographiclib_cython import Geodesic', number=100000)
0.12127103898092173
```

## Gotchas
- If you get this error when doing `import Geodesic`:
```
ImportError: libGeographic.so.17: cannot open shared object file: No such file or directory
```
This means that Python interpreter can't find the shared library. For some reason, `/usr/local/lib` is not searched by default. We need to provide it in the `LD_LIBRARY_PATH`. If you have installed `libGeographic.so` somewhere else, provide that directory instead.
```bash
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
```

- If you get this error when doing `import Geodesic`:
```bash
ImportError: /opt/anaconda/lib/libstdc++.so.6: version `GLIBCXX_3.4.20' not found (required by /usr/local/lib/libGeographic.so.17)
```
Do this (solution found [here](https://github.com/BVLC/caffe/issues/4953)):
```bash
conda install libgcc
```

- If you get this error when doing `import Geodesic`:
```bash
ImportError: /opt/anaconda/lib/python3.5/site-packages/geographiclib_cython.cpython-35m-x86_64-linux-gnu.so: undefined symbol: _ZNK13GeographicLib8Geodesic11Invej
```
Then you have an incompatible version of libGeographic installed. Check where it's coming from:
```bash
ldd /opt/anaconda/lib/python3.5/site-packages/geographiclib_cython.cpython-35m-x86_64-linux-gnu.so
    linux-vdso.so.1 =>  (0x00007fffac2ea000)
    libGeographic.so.9 => /usr/lib/libGeographic.so.9 (0x00007f86ff6bb000)
    ...
```
Remove it and remove the `.whl` from the `pip` cache (do `find ~ -name "*.whl"` to find out where the cache is):
```bash
rm /usr/lib/libGeographic*
rm ~/.cache/pip/wheels/0e/68/e7/7cadf8180052771a12c112ac3cda44363135ecb14cfd57a500/geographiclib_cython_bindings-1.0.0-cp35m-x86_64.whl
```
Then do `pip install` again.

## Useful links
- [`geographiclib` installation manual](https://geographiclib.sourceforge.io/html/install.html)
- [GeographicLib::Geodesic C++ class reference](https://geographiclib.sourceforge.io/html/classGeographicLib_1_1Geodesic.html)
- [GeographicLib Python API reference](https://geographiclib.sourceforge.io/html/python/code.html)
- [Cython: Interfacing with External C Code](http://cython.readthedocs.io/en/latest/src/userguide/external_C_code.html)
- [Cython: Using C++ in Cython](http://cython.readthedocs.io/en/latest/src/userguide/wrapping_CPlusPlus.html)
- [PyPA tutorial on distributing packages](https://packaging.python.org/tutorials/distributing-packages/)
- [Creating a source distribution with sdist](https://docs.python.org/3.6/distutils/sourcedist.html)
