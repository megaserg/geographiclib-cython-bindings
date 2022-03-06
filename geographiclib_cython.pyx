#distutils: language=c++

cimport cgeographiclib
from libcpp cimport bool as cbool
from cpython cimport array
import array
from collections.abc import Iterable

class Geodesic:
    WGS84 = PyGeodesic()

    @staticmethod
    def Sphere(radius=6372795):
        return PyGeodesic(radius)

cdef class PyGeodesic:

    cdef const cgeographiclib.Geodesic* geodesic
    cdef cbool needs_delete

    def __cinit__(self, double radius=0.0):
        if radius == 0.0:
            self.geodesic = &(cgeographiclib.Geodesic.WGS84())
            self.needs_delete = False
        else:
            self.geodesic = new cgeographiclib.Geodesic(radius, 0.0)
            self.needs_delete = True

    def __dealloc__(self):
        if self.needs_delete:
            del self.geodesic

    cpdef Direct(self, double lat1, double lon1, double azi1, double s12):
        cdef double lat2 = 0.0, lon2 = 0.0, azi2 = 0.0
        self.geodesic.Direct(lat1, lon1, azi1, s12, lat2, lon2, azi2)
        return {
             'lat1': lat1, 'lon1': lon1,
             'lat2': lat2, 'lon2': lon2,
             's12': s12, 'azi1': azi1, 'azi2': azi2,
        }

    cpdef Inverse(self, double lat1, double lon1, double lat2, double lon2):
        cdef double s12 = 0.0, azi1 = 0.0, azi2 = 0.0
        self.geodesic.Inverse(lat1, lon1, lat2, lon2, s12, azi1, azi2)
        return {
            'lat1': lat1, 'lon1': lon1,
            'lat2': lat2, 'lon2': lon2,
            's12': s12, 'azi1': azi1, 'azi2': azi2,
        }

    cpdef InverseLine(self, double lat1, double lon1, double lat2, double lon2): 
        return PyGeodesicLine(lat1, lon1, lat2, lon2)


cdef class PyGeodesicLine:

    cdef cgeographiclib.GeodesicLine line
    cdef readonly double s13

    def __cinit__(self, double lat1, double lon1, double lat2, double lon2):
        self.line = cgeographiclib.Geodesic.WGS84().InverseLine(lat1, lon1, lat2, lon2)
        self.s13 = self.line.Distance()
    
    cpdef Position(self, double s12):
        cdef double lat2 = 0.0, lon2 = 0.0
        self.line.Position(s12, lat2, lon2)
        return {
            'lat2': lat2, 'lon2': lon2, 's12': s12
        }

class Rhumb:
    WGS84 = PyRhumb()

cdef class PyRhumb:

    cdef const cgeographiclib.Rhumb* rhumb
    cdef cbool needs_delete

    def __cinit__(self, double radius=0.0):
        if radius == 0.0:
            self.rhumb = &(cgeographiclib.Rhumb.WGS84())
            self.needs_delete = False
        else:
            self.rhumb = new cgeographiclib.Rhumb(radius, 0.0)
            self.needs_delete = True

    def __dealloc__(self):
        if self.needs_delete:
            del self.rhumb

    cpdef Direct(self, double lat1, double lon1, double azi12, double s12):
        cdef double lat2 = 0.0, lon2 = 0.0
        self.rhumb.Direct(lat1, lon1, azi12, s12, lat2, lon2)
        return {
             'lat1': lat1, 'lon1': lon1,
             'lat2': lat2, 'lon2': lon2,
             's12': s12, 'azi12': azi12,
        }

    cpdef Inverse(self, double lat1, double lon1, double lat2, double lon2):
        cdef double s12 = 0.0, azi12 = 0.0
        self.rhumb.Inverse(lat1, lon1, lat2, lon2, s12, azi12)
        return {
            'lat1': lat1, 'lon1': lon1,
            'lat2': lat2, 'lon2': lon2,
            's12': s12, 'azi12': azi12
        }

    cpdef Line(self, double lat1, double lon1, double azi12):
        return PyRhumbLine(self, lat1, lon1, azi12)

    cpdef InverseLine(self, double lat1, double lon1, double lat2, double lon2):
        inverse = self.Inverse(lat1, lon1, lat2, lon2)
        cdef PyRhumbLine line = self.Line(lat1, lon1, inverse['azi12'])
        return line

    cpdef _line_position(self, double lat1, double lon1, double azi12, double s12):
        cdef double lat2 = 0.0, lon2 = 0.0
        self.rhumb.Line(lat1, lon1, azi12).Position(s12, lat2, lon2)
        return {
            'lat2': lat2, 'lon2': lon2, 's12': s12
        }

    cpdef _line_positions(self, double lat1, double lon1, double azi12, array.array[double] s12):

        cdef int num_positions = len(s12)
        cdef array.array lat2 = array.clone(s12, num_positions, zero=False)
        cdef array.array lon2 = array.clone(s12, num_positions, zero=False)

        cdef double *s12_ptr = s12.data.as_doubles
        cdef double *lat2_ptr = lat2.data.as_doubles
        cdef double *lon2_ptr = lon2.data.as_doubles

        rhumb_line_positions(self.rhumb, lat1, lon1, azi12, s12_ptr , num_positions, lat2_ptr, lon2_ptr)

        output = [
            {
                'lat2': lat2[i],
                'lon2': lon2[i],
                's12': s12[i]
            }
            for i in range(num_positions)
        ]

        return output

cdef class PyRhumbLine:
    """
    Because Cython cannot stack allocate classes lacking a nullary constructor,
    and the RhumbLine class is not copy-assignable, this wrapper must construct
    a new RhumbLine instance with each call to a position method.
    """

    cdef readonly PyRhumb rhumb
    cdef readonly double lat1
    cdef readonly double lon1
    cdef readonly double azi12


    def __cinit__(self, PyRhumb rhumb, double lat1, double lon1, double azi12):
        self.rhumb = rhumb
        self.lat1 = lat1
        self.lon1 = lon1
        self.azi12 = azi12

    cpdef Position(self, double s12):
        return self.rhumb._line_position(self.lat1, self.lon1, self.azi12, s12)

    cpdef Positions(self, s12: Iterable[float]):
        """
        Because we can't hold on to a RhumbLine instance in Cython code, this method is provided
        to calculate multiple positions from a given line, only instantiating it once.
        """
        s12_array = array.array('d', s12)
        return self.rhumb._line_positions(self.lat1, self.lon1, self.azi12, s12_array)

cdef extern from "cython_extern_src/rhumb_line_positions.cpp":
    # Source C++ definitions from an external file.
    # Note that this file must be covered by a MANIFEST.in entry to be included in the source distribution by setuptools!
    void rhumb_line_positions(const cgeographiclib.Rhumb *rhumb, double lat1, double lon1, double azi12, double s12[], size_t num_positions, double lat2[], double lon2[])
