import '../config/app_config.dart';

/// Utility class for Google Maps related operations
class MapsUtils {
  MapsUtils._();

  /// Build a Google Maps Static API URL
  ///
  /// [center] - Center point of the map (address or lat,lng)
  /// [zoom] - Zoom level (1-20, default: 11)
  /// [size] - Image size in pixels (default: "600x300")
  /// [markers] - List of marker coordinates in format [lat, lng]
  /// [markerColor] - Color of markers (default: "red")
  ///
  /// Returns the complete static map URL
  static String buildStaticMapUrl({
    required String center,
    int zoom = 11,
    String size = '600x300',
    List<Map<String, double>>? markers,
    String markerColor = 'red',
  }) {
    final apiKey = AppConfig.instance.googleMapsApiKey;
    final buffer = StringBuffer(
      'https://maps.googleapis.com/maps/api/staticmap?',
    );

    // Center
    buffer.write('center=${Uri.encodeComponent(center)}');

    // Zoom
    buffer.write('&zoom=$zoom');

    // Size
    buffer.write('&size=$size');

    // Markers
    // if (markers != null && markers.isNotEmpty) {
    //   final markerString = StringBuffer('markers=color:$markerColor');
    //   for (final marker in markers) {
    //     final lat = marker['lat'];
    //     final lng = marker['lng'];
    //     if (lat != null && lng != null) {
    //       markerString.write('|$lat,$lng');
    //     }
    //   }
    //   buffer.write('&${markerString.toString()}');
    // }

    // API Key
    buffer.write('&key=$apiKey');

    return buffer.toString();
  }

  /// Build a simple static map URL with a single marker
  ///
  /// [center] - Center point (address or lat,lng)
  /// [lat] - Latitude of marker
  /// [lng] - Longitude of marker
  /// [zoom] - Zoom level (default: 11)
  /// [size] - Image size (default: "600x300")
  /// [markerColor] - Marker color (default: "red")
  static String buildStaticMapUrlWithMarker({
    required String center,
    required double lat,
    required double lng,
    int zoom = 11,
    String size = '600x300',
    String markerColor = 'red',
  }) {
    return buildStaticMapUrl(
      center: center,
      zoom: zoom,
      size: size,
      markers: [
        {'lat': lat, 'lng': lng},
      ],
      markerColor: markerColor,
    );
  }
}
