import unittest
import pytest
import timeit
from geographiclib.geodesic import Geodesic
from geographiclib_cython import Geodesic as CythonGeodesic
from geographiclib_cython import Rhumb, PyRhumbLine
from geopy.distance import great_circle

# Run with: python -m pytest tests.py

class TestGeodesic(unittest.TestCase):
    def test_inverse(self):
        actual = CythonGeodesic.WGS84.Inverse(10, 20, 30, 40)
        expected = Geodesic.WGS84.Inverse(10, 20, 30, 40)

        assert actual['s12'] == pytest.approx(expected['s12'], 1e-10)
        assert actual['azi1'] == pytest.approx(expected['azi1'], 1e-10)
        assert actual['azi2'] == pytest.approx(expected['azi2'], 1e-10)

    def test_direct(self):
        actual = CythonGeodesic.WGS84.Direct(10, 20, 30, 4000)
        expected = Geodesic.WGS84.Direct(10, 20, 30, 4000)

        assert actual['lat2'] == pytest.approx(expected['lat2'], 1e-10)
        assert actual['lon2'] == pytest.approx(expected['lon2'], 1e-10)
        assert actual['azi2'] == pytest.approx(expected['azi2'], 1e-10)

    def test_inverse_line(self):
        actual_line = CythonGeodesic.WGS84.InverseLine(10, 20, 30, 40)
        expected_line = Geodesic.WGS84.InverseLine(10, 20, 30, 40)

        assert actual_line.s13 == pytest.approx(expected_line.s13, 1e-10)

        actual_pos = actual_line.Position(100000)
        expected_pos = expected_line.Position(100000)
        assert actual_pos['lat2'] == pytest.approx(expected_pos['lat2'], 1e-10)
        assert actual_pos['lon2'] == pytest.approx(expected_pos['lon2'], 1e-10)

    def test_sphere_distance(self):
        actual = CythonGeodesic.Sphere().Inverse(10, 20, 30, 40)
        expected = great_circle((10, 20), (30, 40))

        assert actual['s12'] == pytest.approx(expected.meters, 1e-10)


class TestRhumb(unittest.TestCase):
    # Test case from the manual for RhumbSolve
    LatLonJFK = 40 + 38/60 + 23/3600, -1*(73 + 46/60 + 44/3600)
    LatLonSIN = 1 + 21/60 + 33/3600, 103 + 59/60 + 22/3600
    azi_JFK_SIN = 103.5828330034
    s_JFK_SIN = 18523563.04238

    def test_direct(self):
        lat1, lon1 = self.LatLonJFK
        azi12 = self.azi_JFK_SIN
        s12 = self.s_JFK_SIN

        expected = {
            'lat2': self.LatLonSIN[0],
            'lon2': self.LatLonSIN[1]
        }

        actual = Rhumb.WGS84.Direct(lat1, lon1, azi12, s12)

        assert actual['lat2'] == pytest.approx(expected['lat2'], 1e-10)
        assert actual['lon2'] == pytest.approx(expected['lon2'], 1e-10)

    def test_inverse(self):
        lat1, lon1 = self.LatLonJFK
        lat2, lon2 = self.LatLonSIN

        expected = {
            'azi12': self.azi_JFK_SIN,
            's12': self.s_JFK_SIN
        }

        actual = Rhumb.WGS84.Inverse(lat1, lon1, lat2, lon2)

        assert actual['s12'] == pytest.approx(expected['s12'], 1e-10)
        assert actual['azi12'] == pytest.approx(expected['azi12'], 1e-10)

    def test_line_position(self):
        lat1, lon1 = self.LatLonJFK
        azi12 = self.azi_JFK_SIN
        s12 = self.s_JFK_SIN

        line = Rhumb.WGS84.Line(lat1, lon1, azi12)

        expected = {
            'lat2': self.LatLonSIN[0],
            'lon2': self.LatLonSIN[1]
        }

        actual = line.Position(s12)

        assert actual['lat2'] == pytest.approx(expected['lat2'], 1e-10)
        assert actual['lon2'] == pytest.approx(expected['lon2'], 1e-10)

    def test_line_positions(self):
        lat1, lon1 = self.LatLonJFK
        azi12 = self.azi_JFK_SIN
        s12 = self.s_JFK_SIN

        line = Rhumb.WGS84.Line(lat1, lon1, azi12)

        distances = [0, 1*s12/4, 2*s12/4, 3*s12/4, s12]
        num_distances = len(distances)

        actual = line.Positions(distances)

        assert len(actual) == num_distances

        assert actual[0]['lat2'] == pytest.approx(self.LatLonJFK[0], 1e-10)
        assert actual[0]['lon2'] == pytest.approx(self.LatLonJFK[1], 1e-10)

        assert actual[num_distances-1]['lat2'] == pytest.approx(self.LatLonSIN[0], 1e-10)
        assert actual[num_distances-1]['lon2'] == pytest.approx(self.LatLonSIN[1], 1e-10)

    def test_line_positions_type(self):
        lat1, lon1 = self.LatLonJFK
        azi12 = self.azi_JFK_SIN

        line = Rhumb.WGS84.Line(lat1, lon1, azi12)

        with pytest.raises(TypeError):
            line.Positions(2)

    def test_line_positions_methods(self):
        lat1, lon1 = self.LatLonJFK
        azi12 = self.azi_JFK_SIN
        s12 = self.s_JFK_SIN

        line = Rhumb.WGS84.Line(lat1, lon1, azi12)
        num_distances = 1000
        distances = [s12*(x/num_distances) for x in range(num_distances)]

        def compute_single():
            return [line.Position(distance) for distance in distances]

        def compute_multiple():
            return line.Positions(distances)

        # Compare equality of results
        output_single = compute_single()
        output_multiple = compute_multiple()
        assert output_single == output_multiple

        # Compare timing
        num_repetitions = 1000
        time_single = timeit.timeit(compute_single, number=num_repetitions)
        time_multiple = timeit.timeit(compute_multiple, number=num_repetitions)

        assert time_multiple < 0.95*time_single  # make sure our optimization is actually helping!

    def test_inverse_line(self):
        lat1, lon1 = self.LatLonJFK
        lat2, lon2 = self.LatLonSIN

        inverse_line = Rhumb.WGS84.InverseLine(lat1, lon1, lat2, lon2)

        assert inverse_line.azi12 == pytest.approx(self.azi_JFK_SIN, 1e-10)

