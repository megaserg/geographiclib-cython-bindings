#include <GeographicLib/Rhumb.hpp>

static void rhumb_line_positions(const GeographicLib::Rhumb *rhumb, double lat1, double lon1, double azi12, double s12[], size_t num_positions, double lat2[], double lon2[] ) {
    GeographicLib::RhumbLine line = rhumb->Line(lat1, lon1, azi12);

    for (size_t i = 0; i < num_positions; i++) {
        line.Position(s12[i], lat2[i], lon2[i]);
    }
}