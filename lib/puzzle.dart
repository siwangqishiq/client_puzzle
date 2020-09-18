import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as UI;

//
Future<UI.Image> loadUiImage(String imageAssetPath) async {
  final ByteData data = await rootBundle.load(imageAssetPath);
  final Completer<UI.Image> completer = Completer();
  UI.decodeImageFromList(Uint8List.view(data.buffer),(UI.Image img){
    return completer.complete(img);
  });

  return completer.future;
}

class PuzzleDemoPage extends StatefulWidget{
  PuzzleDemoPage({Key key}) : super(key: key);

  @override
  _PuzzlePageState createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzleDemoPage>{
  PuzzleEngine _puzzle;

  @override
  void initState() {
    super.initState();
    _puzzle = new PuzzleEngine(this);

    _puzzle.setPuzzle(100, 70);
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: Text("拼图GAME"),
      ),
      body:Center(
        child: _puzzle.isLoaded?_puzzle.createPuzzlePanel():Text("载入中..."),
      )
    );
  }

  @override
  void dispose(){
    _puzzle.onDispose();
    super.dispose();
  }
}

class PuzzleFragment{
  int originIndex;
  int curIndex;

  double left;
  double top;
  double width;
  double height;

  double srcLeft;
  double srcTop;
  double srcWidth;
  double srcHeight;
}

class PuzzleEngine{
  UI.Image srcImage;

  bool isLoaded = false;
  State _ctx;
  List<PuzzleFragment> fragList=[];
  List<List<int>> data = <List<int>>[];

  int _rowNums = 3;//行数
  int _colNums = 3;//列数

  double _viewWidth;
  double _viewHeight;

  Paint _boundPaint;
  Paint _defaultPaint;

  PuzzleEngine(State ctx) {
    this._ctx = ctx;
    init();
    //print("srcImage w = ${srcImage.width}  h = ${srcImage.height}");
  }

  void init() async {
    var rawImage = await loadUiImage("assets/images/test.jpg");

    srcImage = rawImage;

    _defaultPaint = new Paint();

    _boundPaint = new Paint();
    _boundPaint.color = Colors.white;
    _boundPaint.strokeWidth = 2;
    _boundPaint.style = PaintingStyle.stroke;

    _ctx.setState(() {
      isLoaded = true;
    });
  }

  void setPuzzle(int rowNums , int columNums){
    _rowNums = rowNums;
    _colNums = columNums;
  }

  void buildPuzzle() {
    print("viewWidth = $_viewWidth viewHeight = $_viewHeight" );

    final int fragTotalCount = _rowNums * _colNums;

    double fragWidth = srcImage.width / _colNums;
    double fragHeight = srcImage.height / _rowNums;

    double fragViewWidth = _viewWidth / _colNums;
    double fragViewHeight = _viewHeight / _rowNums;

    // print("fragTotalCount =  $fragTotalCount");

    for(int i =0 ; i < _rowNums ; i++){
      var line=<int>[];
      for(int j = 0 ; j < _colNums; j++){
        int val = i * _colNums + j;

        if(val == fragTotalCount - 1){// last is empty
          val = -1;
        }
        line.add(val);

        if(val >= 0){ //add frag 
          PuzzleFragment frag = new PuzzleFragment();
          frag.originIndex = i;
          frag.curIndex = i;

          frag.left = fragViewWidth * j;
          frag.top = fragViewHeight * i;
          frag.width = fragViewWidth;
          frag.height = fragViewHeight;

          frag.srcLeft = fragWidth * j;
          frag.srcTop = fragHeight * i;
          frag.srcWidth = fragWidth;
          frag.srcHeight = fragHeight;

          fragList.add(frag);
        }
      }//end for j
      data.add(line);
    }//end for i

    debugPrintDataArray();

    _shuffle(1);
  }

  //
  void _shuffle(int step){
    
  }

  void debugPrintDataArray(){
    for(int i = 0 ; i < data.length ; i++){
      print(data[i]);
    }
  }
  
  Widget createPuzzlePanel(){
    return GestureDetector(
      child: CustomPaint(
        painter: PuzzlePainter(this),
        size: Size(double.infinity, double.infinity),
      ),

    );
  }

  //get view size
  void onGetViewSize(double vW , double vH){
    _viewWidth = vW;
    _viewHeight = vH;

    buildPuzzle();
  }

  //main loop
  void render(Canvas canvas, Size size){
    
    for(PuzzleFragment frag in fragList){
      canvas.drawImageRect(srcImage, Rect.fromLTRB(frag.srcLeft, frag.srcTop, frag.srcLeft + frag.srcWidth, frag.srcTop + frag.srcHeight),
                           Rect.fromLTRB(frag.left, frag.top, frag.left + frag.width, frag.top + frag.height), _defaultPaint);

      //draw bound
      canvas.drawRect(Rect.fromLTRB(frag.left, frag.top, frag.left + frag.width, frag.top + frag.height), _boundPaint);
    }//end for each

    // canvas.drawRect(Rect.fromLTRB(0, 0, size.width/2 , size.height/2), _testPaint);

    // UI.Image img = _puzzleContext.srcImage;
    
    // print("imageSize img = ${img == null} width = ${img.width}  height = ${img.height}");
    //canvas.drawImage(img, , paint)
    // canvas.drawImageRect(img, Rect.fromLTRB(0, 0, img.width.toDouble(), img.height.toDouble()), 
    //   Rect.fromLTRB(0, 0, size.width , size.height), imgPaint);
  }

  //on Destory
  void onDispose(){
    srcImage.dispose();
  }

}//end class

class PuzzlePainter extends CustomPainter{
  PuzzleEngine _puzzleContext;
  Paint _testPaint;
  Paint imgPaint;

  double viewWidth = -1;
  double viewHeight = -1;

  PuzzlePainter(PuzzleEngine context){
    this._puzzleContext = context;

    _init();
  }

  void _init(){
    _testPaint = Paint();
    imgPaint = Paint();
    _testPaint.color = Colors.blueAccent;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if(size.width.toInt() != viewWidth || size.height.toInt() != viewHeight){
      viewWidth = size.width;
      viewHeight = size.height;

      _puzzleContext.onGetViewSize(viewWidth, viewHeight);
    }

    _puzzleContext.render(canvas , size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}//end class

