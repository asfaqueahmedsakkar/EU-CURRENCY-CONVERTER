class Rate {
  String name;
  String code;
  String countryCode;
  Map<String, dynamic> rates;

  Rate.fromJson(Map<String, dynamic> json) {
    name = json["name"];
    code = json["code"];
    countryCode = json["country_code"];

    List<dynamic> periods = json["periods"];
    Map<String, dynamic> period = periods.first;
    rates = period["rates"];
  }
}
