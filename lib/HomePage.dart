import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:currency_app/RateModel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Rate> taxRates;
  int initial;
  int selectedRate = 0;
  TextEditingController _textEditingController;
  StreamController _controller;
  double rate = 0.0;

  double cur = 0, tax = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _controller = new StreamController();
    _textEditingController = new TextEditingController();
    _textEditingController.addListener(() {
      setState(() {
        onValueChange();
      });
    });
  }

  @override
  void dispose() {
    _controller.close();
    //_textEditingController.removeListener(onValueChange());
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            tooltip: "Refresh API data",
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        title: Transform.rotate(
          child: Text(
            "ECC",
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  offset: Offset(
                    2.0,
                    2.0,
                  ),
                ),
              ],
            ),
          ),
          angle: -pi * .25,
        ),
      ),
      body: StreamBuilder(
        stream: _controller.stream,
        builder: (context, snapShot) {
          if (!snapShot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return getUiContent();
          }
        },
      ),
    );
  }

  Widget getUiContent() {
    int id = 0;
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _getTitle(text: "EU CURRENCY\nCONVERTER"),
            Row(
              children: <Widget>[
                Text(
                  "Country Name:",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(
                  width: 16.0,
                ),
                Expanded(
                  child: Container(
                    height: 40.0,
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ),
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8.0)),
                    child: DropdownButton(
                      value: initial,
                      isExpanded: true,
                      items: taxRates.map((rate) {
                        return DropdownMenuItem(
                          value: id++,
                          child: Container(
                            child: Text(
                              rate.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (id) {
                        setState(
                          () {
                            initial = id;
                            selectedRate = 0;
                            rate = taxRates[initial]
                                .rates
                                .values
                                .toList()[selectedRate];
                            onValueChange();
                          },
                        );
                      },
                      iconSize: 20.0,
                      icon: Icon(Icons.keyboard_arrow_down),
                      elevation: 1,
                      underline: SizedBox(),
                    ),
                  ),
                ),
              ],
            ),
            _commonGap(16.0),
            TextFormField(
              controller: _textEditingController,
              textAlign: TextAlign.left,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 12.0,
                ),
                labelText: "Currency Amount",
              ),
              onFieldSubmitted: (sa) {
                FocusScope.of(context).requestFocus(FocusNode());
              },
            ),
            _commonGap(24.0),
            _radioGroupOfRate(),
            _commonGap(24.0),
            _getCalculations(),
            SizedBox(
              height: 40.0,
            ),
            Text(
              "NB: Vat rate is provided for currently active rates\n\nNB: This calculation is based on data fetched from\nhttps://jsonvat.com",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
              ),
            )
          ],
        ),
      ),
    );
  }

  SizedBox _commonGap(double gap) {
    return SizedBox(
      height: gap,
    );
  }

  Widget _getTitle({String text}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 32.0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _radioGroupOfRate() {
    int id = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          "Vat rates:",
          style: TextStyle(color: Colors.grey, fontSize: 14.0),
        ),
        SizedBox(
          height: 4.0,
        ),
        Column(
          children: taxRates[initial].rates.keys.map(
            (rate) {
              return SizedBox(
                height: 32.0,
                child: _getRadioButton(
                  title: "$rate(${taxRates[initial].rates[rate]}%)",
                  val: id++,
                  rate: taxRates[initial].rates[rate],
                ),
              );
            },
          ).toList(),
        )
      ],
    );
  }

  Row _getRadioButton(
      {@required String title, @required int val, @required double rate}) {
    return Row(
      children: <Widget>[
        Radio(
          value: val,
          activeColor: Colors.pink,
          groupValue: selectedRate,
          onChanged: (int value) {
            setState(
              () {
                selectedRate = value;
                this.rate = rate;
                onValueChange();
              },
            );
          },
        ),
        Text(title)
      ],
    );
  }

  Widget _getCalculations() {
    TextStyle _commonStyle = TextStyle(
      color: Colors.grey,
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 132.0,
                child: Text(
                  "Original Amount =",
                  style: _commonStyle,
                ),
              ),
              Text(
                "$cur",
                style: _commonStyle,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 132.0,
                child: Text(
                  "Tax =",
                  style: _commonStyle,
                ),
              ),
              Text(
                "$tax",
                style: _commonStyle,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            "  (+)",
            style: _commonStyle,
          ),
        ),
        Divider(
          height: 2.0,
          color: Colors.grey,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 132.0,
                child: Text(
                  "Total =",
                  style: _commonStyle,
                ),
              ),
              Text(
                "${tax + cur}",
                style: _commonStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _loadData() async {
    String response = await http.read("https://jsonvat.com/");
    Map<String, dynamic> jsonResp = jsonDecode(response);
    List<dynamic> rates = jsonResp["rates"];
    List<Rate> rateList = new List();
    for (Map<String, dynamic> rate in rates) rateList.add(Rate.fromJson(rate));
    taxRates = rateList;
    setState(() {
      FocusScope.of(context).requestFocus(FocusNode());
      _textEditingController.clear();
      initial = 0;
      selectedRate = 0;
      rate = taxRates[initial].rates.values.toList()[selectedRate];
      cur = 0;
      tax = 0;
      onValueChange();
      _controller.add("done");
    });
  }

  onValueChange() {
    cur = _textEditingController.text.isEmpty
        ? 0.0
        : double.parse(
            _textEditingController.text,
          );
    tax = cur * rate / 100;
  }
}
