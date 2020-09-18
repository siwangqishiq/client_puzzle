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
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: Text("拼图GAME"),
      ),
      body:Center(
        child: _puzzle.isLoaded?_puzzle.createPuzzlePanel(context.size.width , context.size.height):
                                Text("载入中..."),
      )
    );
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

  int _rowNums;//行数
  int _colNums;//列数

  int _viewWidth;
  int _viewHeight;

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

    _ctx.setState(() {
      isLoaded = true;
    });
  }

  void buildPuzzle(int rowNums , int columNums  , int viewWidth , int viewHeight){
    _rowNums = rowNums;
    _colNums = columNums;

    _viewWidth = viewWidth;
    _viewHeight = viewHeight;

    print("viewWidth = $_viewWidth               viewHeight = $_viewHeight" );

    final int fragTotalCount = _rowNums * _colNums;

    double fragWidth = srcImage.width / columNums;
    double fragHeight = srcImage.height / rowNums;

    // print("fragTotalCount =  $fragTotalCount");

    for(int i =0 ; i < _colNums ; i++){
      var line=<int>[];
      for(int j = 0 ; j < _rowNums; j++){
        int val = i * _rowNums + j;

        if(val == fragTotalCount - 1){// last is empty
          val = -1;
        }
        line.add(val);

        if(val >= 0){ //add frag 

        }
      }//end for j
      data.add(line);
    }//end for i

    debugPrintDataArray();
  }

  void debugPrintDataArray(){
    for(int i = 0 ; i < data.length ; i++){
      print(data[i]);
    }
  }
  
  Widget createPuzzlePanel(double width , double height){
    buildPuzzle(3 , 3 , width.toInt() , height.toInt());
    return GestureDetector(
      child: CustomPaint(
        painter: PuzzlePainter(this),
        size: Size(width, height),
      ),

    );
  }

  //main loop
  void render(Canvas canvas, Size size){
    
    for(PuzzleFragment frag in fragList){
      canvas.drawImageRect(srcImage, Rect.fromLTRB(frag.srcLeft, frag.srcHeight, frag.srcLeft + frag.srcWidth, frag.srcTop + frag.srcHeight),
                           Rect.fromLTRB(frag.left, frag.top, frag.left + frag.width, frag.top + frag.height), _defaultPaint);
    }//end for each

    // canvas.drawRect(Rect.fromLTRB(0, 0, size.width/2 , size.height/2), _testPaint);

    // UI.Image img = _puzzleContext.srcImage;
    
    // print("imageSize img = ${img == null} width = ${img.width}  height = ${img.height}");
    //canvas.drawImage(img, , paint)
    // canvas.drawImageRect(img, Rect.fromLTRB(0, 0, img.width.toDouble(), img.height.toDouble()), 
    //   Rect.fromLTRB(0, 0, size.width , size.height), imgPaint);
  }

  void onDispose(){

  }
}

class PuzzlePainter extends CustomPainter{
  PuzzleEngine _puzzleContext;
  Paint _testPaint;
  Paint imgPaint;

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
    _puzzleContext.render(canvas , size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}//end class

