import sys
from distutils.core import setup, Extension

USE_CYTHON = False
if "--cython" in sys.argv:
    sys.argv.remove("--cython")
    USE_CYTHON = True

file_ext = ".pyx" if USE_CYTHON else ".cpp"

extensions = [Extension(
    "geographiclib_cython",
    ["geographiclib_cython"+file_ext],
    libraries=["Geographic"]
)]

if USE_CYTHON:
    from Cython.Build import cythonize
    extensions = cythonize(extensions)

setup(
    name="geographiclib-cython-bindings",
    description="""Cython extension module for C++ geographiclib functions""",
    version="0.1.3",
    author="Sergey Serebryakov",
    author_email="sergey@serebryakov.info",
    url="https://github.com/megaserg/geographiclib-cython-bindings",
    license="MIT",
    ext_modules=extensions
)
