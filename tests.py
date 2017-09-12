import unittest
import pytest
from geographiclib.geodesic import Geodesic
from geographiclib_cython import Geodesic as CythonGeodesic
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
