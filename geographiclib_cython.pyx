#distutils: language=c++

cimport cgeographiclib
from libcpp cimport bool as cbool

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
