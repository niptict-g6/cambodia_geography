import 'package:cambodia_geography/configs/route_config.dart';
import 'package:cambodia_geography/constants/api_constant.dart';
import 'package:cambodia_geography/constants/config_constant.dart';
import 'package:cambodia_geography/exports/exports.dart';
import 'package:cambodia_geography/helpers/app_helper.dart';
import 'package:cambodia_geography/mixins/cg_media_query_mixin.dart';
import 'package:cambodia_geography/mixins/cg_theme_mixin.dart';
import 'package:cambodia_geography/models/places/place_list_model.dart';
import 'package:cambodia_geography/models/places/place_model.dart';
import 'package:cambodia_geography/models/tb_province_model.dart';
import 'package:cambodia_geography/screens/admin/local_widgets/place_list.dart';
import 'package:cambodia_geography/screens/district/district_screen.dart';
import 'package:cambodia_geography/screens/map/map_screen.dart';
import 'package:cambodia_geography/screens/place_detail/local_widgets/place_title.dart';
import 'package:cambodia_geography/services/apis/places/places_api.dart';
import 'package:cambodia_geography/utils/translation_utils.dart';
import 'package:cambodia_geography/widgets/cg_bottom_nav_wrapper.dart';
import 'package:cambodia_geography/widgets/cg_custom_shimmer.dart';
import 'package:cambodia_geography/widgets/cg_markdown_body.dart';
import 'package:cambodia_geography/widgets/cg_network_image_loader.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:weather/weather.dart';

class ProvinceDetailScreen extends StatefulWidget {
  const ProvinceDetailScreen({
    Key? key,
    required this.province,
    this.info,
  }) : super(key: key);

  final TbProvinceModel province;
  final PlaceModel? info;

  @override
  _ProvinceDetailScreenState createState() => _ProvinceDetailScreenState();
}

class _ProvinceDetailScreenState extends State<ProvinceDetailScreen> with CgThemeMixin, CgMediaQueryMixin {
  late ScrollController scrollController;
  late PageController pageController;
  late WeatherFactory weatherFactory;
  Future<Weather>? weather;
  LatLng? latLng;
  PlaceListModel? placeList;
  late PlacesApi placesApi;

  PlaceModel? get placeModel => placeList?.items?.isNotEmpty == true ? placeList?.items?.first : null;
  double get expandedHeight => MediaQuery.of(context).size.width;

  @override
  void initState() {
    scrollController = ScrollController();
    pageController = PageController();
    weatherFactory = WeatherFactory(ApiConstant.openWeatherMapApiKey);
    placesApi = PlacesApi();
    super.initState();
    loadProvince();

    double? latitude = double.tryParse(widget.province.latitude ?? "");
    double? longitudes = double.tryParse(widget.province.longitudes ?? "");

    if (latitude != null && longitudes != null) {
      latLng = LatLng(latitude, longitudes);
      weather = _setWeather(latitude, longitudes);
    }
  }

  Future<Weather> _setWeather(double latitude, double longitudes) async {
    return await weatherFactory.currentWeatherByLocation(latitude, longitudes);
  }

  Future<void> loadProvince({bool loadMore = false}) async {
    if (widget.info != null) {
      if (!mounted) return;
      setState(() {
        placeList = PlaceListModel(items: [widget.info!]);
      });
      return;
    }

    if (loadMore && !(this.placeList?.hasLoadMore() == true)) return;
    String? page = loadMore ? placeList?.links?.getPageNumber().next.toString() : null;

    final result = await placesApi.fetchAllPlaces(
      type: PlaceType.province,
      provinceCode: widget.province.code,
      page: page,
    );

    if (placesApi.success()) {
      if (!mounted) return;
      setState(() {
        if (placeList != null && loadMore) {
          placeList?.add(result);
        } else {
          placeList = result;
        }
      });
    }
  }

  List<String> get images {
    if (placeList?.items != null) {
      if (placeList?.items?[0].images == null) return [];
      return placeList!.items![0].images!.map((e) => e.url.toString()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: buildBottomNavigationBar(),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          CgImageAppBar(
            expandedHeight: expandedHeight,
            pageController: pageController,
            title: widget.province.nameTr ?? "",
            images: images,
            scrollController: scrollController,
            actions: [
              IconButton(
                icon: Icon(Icons.info),
                onPressed: () {
                  showInfoModalBottomSheet(
                    context,
                    widget.province.toJson(),
                  );
                },
              ),
            ],
          ),
          buildBody(),
        ],
      ),
    );
  }

  SliverList buildBody() {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          PlaceTitle(
            title: widget.province.nameTr.toString(),
            provinceCode: widget.province.code,
            lat: double.tryParse(widget.province.latitude ?? '0'),
            lon: double.tryParse(widget.province.longitudes ?? '0'),
            place: placeModel,
          ),
          buildContainer(
            title: tr('tile.weather'),
            body: buildWeather(),
          ),
          buildContainer(
            margin: EdgeInsets.only(bottom: ConfigConstant.margin2),
            title: tr('tile.about_province'),
            visible: placeList?.items?[0].body != null,
            body: buildAboutProvince(),
          ),
          buildContainer(
            margin: EdgeInsets.only(bottom: ConfigConstant.margin2),
            title: tr('tile.direction'),
            body: buildProvinceDirection(),
          ),
        ],
      ),
    );
  }

  Widget buildProvinceDirection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildHeaderTile(
          title: tr('tile.north'),
          subtitle: widget.province.northTr,
          leading: Icon(Icons.north),
        ),
        buildHeaderTile(
          title: tr('tile.east'),
          subtitle: widget.province.eastTr,
          leading: Icon(Icons.east),
        ),
        buildHeaderTile(
          title: tr('tile.south'),
          subtitle: widget.province.southTr,
          leading: Icon(Icons.south),
        ),
        buildHeaderTile(
          title: tr('tile.west'),
          subtitle: widget.province.westTr,
          leading: Icon(Icons.west),
        ),
      ],
    );
  }

  Widget buildAboutProvince() {
    return CgMarkdownBody(placeList?.items?[0].body ?? "");
  }

  Widget buildContainer({
    required String title,
    required Widget body,
    EdgeInsetsGeometry? margin,
    bool visible = true,
  }) {
    if (!visible) return SizedBox();
    return Container(
      color: colorScheme.surface,
      margin: margin ?? const EdgeInsets.symmetric(vertical: ConfigConstant.margin2),
      padding: const EdgeInsets.all(ConfigConstant.margin2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.subtitle1?.copyWith(color: textTheme.caption?.color, fontWeight: FontWeight.bold),
          ),
          body,
        ],
      ),
    );
  }

  Widget buildWeather() {
    return FutureBuilder<Weather>(
      future: weather,
      builder: (context, snapshot) {
        // Map<String, dynamic>? json = snapshot.data?.toJson();
        Weather? weather = snapshot.data;
        // Temparature
        String celsius = "${numberTr(weather?.temperature?.celsius?.toInt())} °C";
        String fahrenheit = "${numberTr(weather?.temperature?.fahrenheit?.toInt())} °F";
        // Weather image
        String? weatherImage;
        String icon = weather?.weatherIcon ?? '';
        if (weather?.weatherIcon != null) {
          weatherImage = "http://openweathermap.org/img/wn/$icon@2x.png";
        }
        // Wind
        String windSpeed = numberTr(weather?.windSpeed);
        String windDegree = numberTr(weather?.windDegree);
        String windDir = AppHelper.getCompassDirection(weather?.windDegree ?? 0, context);
        IconData iconDirection = AppHelper.getDirectionIcon(weather?.windDegree ?? 0);

        if (snapshot.hasError) return SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeaderTile(
              title: tr('tile.temperature'),
              subtitle: snapshot.hasData ? '$celsius | $fahrenheit' : null,
              weatherImage: weatherImage,
            ),
            buildHeaderTile(
              title: tr('tile.wind'),
              subtitle: snapshot.hasData ? '$windSpeed m/s | $windDir ($windDegree°)' : null,
              leading: Icon(iconDirection),
            ),
          ],
        );
      },
    );
  }

  ListTile buildHeaderTile({
    required String title,
    String? subtitle,
    String? weatherImage,
    Widget? leading,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: buildTextCrossFade(
        subtitle != null ? title : null,
        color: colorScheme.primary,
        shimmerWidth: 50,
      ),
      subtitle: buildTextCrossFade(subtitle),
      tileColor: colorScheme.surface,
      leading: AspectRatio(
        aspectRatio: 1,
        child: weatherImage != null || leading != null
            ? Container(
                alignment: Alignment.center,
                child: weatherImage != null ? CgNetworkImageLoader(imageUrl: weatherImage) : leading,
              )
            : CgCustomShimmer(child: Container(color: Colors.white)),
      ),
    );
  }

  Widget buildTextCrossFade(String? text, {Color? color, double? shimmerWidth}) {
    return AnimatedCrossFade(
      duration: ConfigConstant.duration,
      crossFadeState: text != null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      sizeCurve: Curves.ease,
      firstChild: Container(
        width: double.infinity,
        child: Text(
          text ?? "",
          style: TextStyle(color: color),
        ),
      ),
      secondChild: CgCustomShimmer(
        child: Row(
          children: [
            Container(
              height: 12,
              width: shimmerWidth ?? 100,
              color: colorScheme.surface,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomNavigationBar() {
    PlaceModel? item = placeList?.items?[0];
    return CgBottomNavWrapper(
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (placeList?.items?[0].id == null) return;
              await Navigator.pushNamed(
                context,
                RouteConfig.COMMENT,
                arguments: placeList?.items?[0],
              );
            },
            icon: Icon(
              Icons.mode_comment,
              color: colorScheme.primary,
            ),
          ),
          AnimatedCrossFade(
            duration: ConfigConstant.duration,
            crossFadeState: item != null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            sizeCurve: Curves.ease,
            firstChild: Container(
              child: Text(
                numberTr((item?.commentLength ?? 0)),
                style: textTheme.caption,
              ),
              padding: const EdgeInsets.symmetric(horizontal: ConfigConstant.margin1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ConfigConstant.objectHeight1),
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              ),
            ),
            secondChild: const SizedBox(width: ConfigConstant.iconSize2),
          ),
          const Spacer(),
          // IconButton(
          //   onPressed: () {},
          //   icon: Icon(
          //     Icons.share,
          //     color: colorScheme.primary,
          //   ),
          // ),
          // IconButton(
          //   onPressed: () {},
          //   icon: Icon(
          //     Icons.bookmark,
          //     color: colorScheme.primary,
          //   ),
          // )
        ],
      ),
    );
  }
}
