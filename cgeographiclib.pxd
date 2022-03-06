#distutils: language=c++

cdef extern from "GeographicLib/Geodesic.hpp" namespace "GeographicLib":
    cdef cppclass Geodesic:
        Geodesic(double a, double f)
        double Direct(double lat1, double lon1, double azi1, double s12, double &lat2, double &lon2, double &azi2)
        double Inverse(double lat1, double lon1, double lat2, double lon2, double &s12, double &azi1, double &azi2)
        GeodesicLine InverseLine(double lat1, double lon1, double lat2, double lon2)
        @staticmethod
        Geodesic& WGS84()

cdef extern from "GeographicLib/GeodesicLine.hpp" namespace "GeographicLib":
    cdef cppclass GeodesicLine:
        double Distance()
        double Position(double s12, double &lat2, double &lon2)

cdef extern from "GeographicLib/Rhumb.hpp" namespace "GeographicLib":
    cdef cppclass Rhumb:
        Rhumb(double a, double f)  except +
        double Direct(double lat1, double lon1, double azi12, double s12, double &lat2, double &lon2)
        double Inverse(double lat1, double lon1, double lat2, double lon2, double &s12, double &azi12)
        RhumbLine Line(double lat1, double lon1, double azi12)
        @staticmethod
        Rhumb& WGS84()

cdef extern from "GeographicLib/Rhumb.hpp" namespace "GeographicLib":
    cdef cppclass RhumbLine:
        double Position(double s12, double &lat2, double &lon2)