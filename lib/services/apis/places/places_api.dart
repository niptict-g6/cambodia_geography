import 'package:cambodia_geography/screens/admin/local_widgets/place_list.dart';
import 'package:cambodia_geography/services/apis/places/base_places_api.dart';

class PlacesApi extends BasePlacesApi {
  @override
  String get nameInUrl => "places";

  @override
  fetchAllPlaces({
    String? keyword,
    PlaceType? type,
    String? provinceCode,
    String? districtCode,
    String? villageCode,
    String? communeCode,
    String? page,
  }) {
    return super.fetchAll(queryParameters: {
      "type": type.toString().replaceAll("PlaceType.", ""),
      "province_code": provinceCode,
      "district_code": districtCode,
      "village_code": villageCode,
      "commune_code": communeCode,
      "page": page,
    });
  }
}
