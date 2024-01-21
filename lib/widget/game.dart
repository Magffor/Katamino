import '../model/piece.dart';
import '../util/std_coords.dart';
import '../model/grid.dart';
import 'package:flutter/material.dart';

class Game extends StatefulWidget {
  final String title;

  const Game({super.key, required this.title});
  
  @override
  State<Game> createState() => GameState();
}

class MutableOffset {
  Offset _offset = Offset(0,0);

  MutableOffset(Offset off){
    _offset = off;
  }

  Offset getOffset(){
    return _offset;
  }

  void setOffset(Offset newOff){
    _offset = newOff;
  }
}

class GameState extends State<Game> {
  
  final Piece _L = Piece.lshape();
  final List<Piece> _pieces = [Piece.lshape(), Piece.ushape()];
  final Grid _g = Grid(5, 12);
  Map<Piece,List<MutableOffset>> _offsetmap = Map();
  GlobalKey _draggableKey = GlobalKey();
  Offset _feedbackOffset = Offset.zero;

  void initOffsetPiece(Piece piece){
    final entry = <Piece,List<MutableOffset>>{piece : <MutableOffset>[]};
    for(StdCoords c in piece.getPath().getCoordsList()){
      entry[piece]?.add(MutableOffset(Offset(c.getYCoords() * 50, c.getXCoords() * 50)));
    }
    _offsetmap.addEntries(entry.entries);
  }
  @override
  void initState() {
    for(Piece piece in _pieces){
      initOffsetPiece(piece);
    }
    int maxX = 1920;
    double i = 0;
    for (Piece p in _pieces) {
      p.setOffset(Offset((maxX / _pieces.length) * i, 1000));
      i++;
    }
    super.initState();
  }
  
  void _addPiece(Piece p, StdCoords c) {
    setState(() {
      if (!_g.pieceAlreadyPlaced(p)) {
        _g.putPiece(p, c);
      }
    });
  }

  void _remove(Piece p, Offset baseOffset) {
    setState(() {
      if (_g.pieceAlreadyPlaced(p)) {
        _g.removePiece(p);
/*         p.setOffset(Offset (p.getCenter().getXCoords() * 50, p.getCenter().getYCoords() * 50));
 */        p.setOffset(baseOffset); 
        }
    });
  }

  void _rotate(Piece p) {
    setState(() {
      if (!_g.pieceAlreadyPlaced(p)) {
        p.rotate();
      }
    });
  }

  void _flip(Piece p) {
    setState(() {
      if (!_g.pieceAlreadyPlaced(p)) {
        p.flip();
      }
    });
  }

  Future<Widget> _renderGrid() async{
    
    return Positioned(
          left: 500,
          top: 500,
          child : SizedBox(
            width : _g.getNbCols() * 50,
            height : _g.getNbRows() * 50,
            child : GridView.builder(
              itemCount : _g.getNbRows() * _g.getNbCols(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _g.getNbCols(),
              ),
              itemBuilder: (BuildContext context, int index){
                int i = index ~/ _g.getNbCols();
                int j = index % _g.getNbCols();
                return DragTarget<Piece>( 
                  builder: (context, candidateData, rejectedData){
                    return ColoredBox(
                      color: (_g.get(i, j) == -1) ? (candidateData.isEmpty) ? Colors.white :
                      (_g.isValid(candidateData[0] as Piece, StdCoords.fromInt(i, j))) ? Colors.grey : Colors.red : Piece.colors[_g.get(i, j)],
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Text(_g.get(i, j).toString()),
                      )
                    );
                  },
                  onWillAccept: (data){
                    if(data.runtimeType == Null){
                      return false;
                    }
                    return _g.isValid(data as Piece, StdCoords.fromList([i, j]));
                  },
                  onAccept: (data){
                    _addPiece(data, StdCoords.fromInt(i, j));
                  }
                );
              },
            ),
          )
    );
  }

  Widget _positionedPiece(Piece p, Offset baseOffset) {
    Offset temp_offset = p.getOffset();
    return Positioned(
        left: p.getOffset().dx,
        top: p.getOffset().dy,
        child: Visibility(
          visible: !_g.pieceAlreadyPlaced(p),
          maintainSize: true,
          maintainState: true,
          maintainAnimation: true,
          maintainInteractivity: true,
          child: Draggable<Piece>(
          data: p,
          dragAnchorStrategy: p.centerDragAnchorStrategy,
          child: Container(
            child: CustomPaint(
                size: Size(250, 250),
                painter: PiecePainter(p, Colors.red),
            ),
          ),
          feedback: Container(
              child: CustomPaint(
                size: Size(250, 250),
                painter: PiecePainter(p, Colors.grey),
              ),
          ),
          childWhenDragging: Container(
            child: CustomPaint(
                size: Size(250, 250),
                painter: PiecePainter(p, Colors.green),
              ),
            ),

          onDragStarted: () {
            if(_g.pieceAlreadyPlaced(p)){
              _remove(p, baseOffset);
            }

          },
          /* onDraggableCanceled: (velocity, offset) {
            p.setOffset(baseOffset);
          }, */
          onDragEnd: (details) {
            setState(() {
              if (_g.pieceAlreadyPlaced(p)) {
                p.setOffset(details.offset);
              } else {
                p.setOffset(baseOffset);
              }
            });
            
            /* temp_offset = details.offset;
            print("end");
            print(details.offset);
            print(temp_offset); */
          },
          /* onDragCompleted: () {
            p.setOffset(temp_offset); 
            print("nouveau");
            print(temp_offset);
          }, */
          )), 
      );
  }
  List<Widget> createChildren(List<Piece> pieces){
    List<Widget> children = [Scaffold(
        body: FutureBuilder(
          future : _renderGrid(),
          builder: (context, snapshot){
            if(snapshot.hasData){
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ColoredBox(
                      color: Colors.red,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),
                      )
                    ),
                    ColoredBox(
                      color: Colors.blue,
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: SizedBox(
                          width: _g.getNbCols() * 50.0,
                          child: snapshot.data as Widget,
                        ),
                      ),
                    ),
                    /* FloatingActionButton(onPressed: (){
                      _remove(_L);
                    },
                    child: const Icon(Icons.remove)), */
                    FloatingActionButton(onPressed: (){
                      _rotate(_L);
                    },
                    child : const Icon(Icons.arrow_back)),
                    FloatingActionButton(onPressed: (){
                      _flip(_L);
                    },
                    child: const Icon(Icons.flip),),
                  ],
                )
              );
            } else {
              return Center(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ),
              );
            }
          }
        ),
      ),   
    ];
    int maxX = 1920;
    double i = 0;
    for(Piece p in pieces){
      children.add(_positionedPiece(p, Offset((maxX / pieces.length) * i, 1000)));
      i++;
    }
    return children;
  }
  @override
  Widget build(BuildContext context) {
    List<Widget> _children = createChildren(_pieces);
    _children.addAll(createDraggablePieces());
    return Stack(
      children : _children
    );
  }

  void updateOffsetPiece(MutableOffset off, List<MutableOffset> lf, Offset newOff){
    for(MutableOffset o in lf){
      if(o != off){
        o.setOffset(newOff + (o.getOffset() - off.getOffset()));
      }
    }
    off.setOffset(newOff);
  }

  List<Widget> createDraggablePieces(){
    List<Widget> ret = [];
      print("---------Game---------");
    for(Piece p in _pieces){
      for(MutableOffset off in _offsetmap[p]!){
        print(off.getOffset());
        ret.add(
          Positioned(
          left: off.getOffset().dx,
          top: off.getOffset().dy,
          child : Draggable<Piece>(
              data: p,
              feedbackOffset: _feedbackOffset,
              feedback: CustomPaint(
                size: Size(250, 250),
                painter: PiecePainter.good(p, Colors.grey, _offsetmap[p]!, off),
              ),
              onDragStarted: () {
                _remove(p, Offset(0,0));
              },
              onDragEnd: (details) {
                setState(() {
                  updateOffsetPiece(off, _offsetmap[p]!, details.offset);
                });
              },  
              child: Container(
                  width: 50,
                  height: 50,
                  color: p.getColor(),
              ),    
            ) 
          )
        );
      }
    }
    return ret;
  }
}
/* List<Widget> test(p) {  

  return [
    Positioned(
      left: offset1.getOffset().dx,
      top: offset1.getOffset().dy,
      child : Draggable<Piece>(
            feedback: Container(
                width: 50,
                height: 50,
                color: Colors.purple,
            ),
            onDragEnd: (details) {
              setState(() {
                updateOffsetPiece(offset1, lf, details.offset);
              });
            },  
            child: Container(
                width: 50,
                height: 50,
                color: Colors.pink,
            ),    
      )
    ),
    Positioned(
      left: offset2.getOffset().dx,
      top: offset2.getOffset().dy,
      child : Draggable<Piece>(
            feedback: Container(
                width: 50,
                height: 50,
                color: Colors.purple,
            ),
            onDragEnd: (details) {
              setState(() {
                updateOffsetPiece(offset2, lf, details.offset);
              });
            },  
            child: Container(
                width: 50,
                height: 50,
                color: Colors.pink,
            ),    
      )
    ),
    Positioned(
      left: offset3.getOffset().dx,
      top: offset3.getOffset().dy,
      child : Draggable<Piece>(
            feedback: Container(
                width: 50,
                height: 50,
                color: Colors.purple,
            ),
            onDragEnd: (details) {
              setState(() {
                updateOffsetPiece(offset3, lf, details.offset);
              });
            },  
            child: Container(
                width: 50,
                height: 50,
                color: Colors.pink,
            ),    
      )
    ),
    Positioned(
      left: offset4.getOffset().dx,
      top: offset4.getOffset().dy,
      child : Draggable<Piece>(
            feedback: Container(
                width: 50,
                height: 50,
                color: Colors.purple,
            ),
            onDragEnd: (details) {
              setState(() {
                updateOffsetPiece(offset4, lf, details.offset);
              });
            },  
            child: Container(
                width: 50,
                height: 50,
                color: Colors.pink,
            ),    
      )
    ),
    Positioned(
      left: offset5.getOffset().dx,
      top: offset5.getOffset().dy,
      child : Draggable<Piece>(
            feedback: Container(
                width: 50,
                height: 50,
                color: Colors.purple,
            ),
            onDragEnd: (details) {
              setState(() {
                updateOffsetPiece(offset5, lf, details.offset);
              });
            },  
            child: Container(
                width: 50,
                height: 50,
                color: Colors.pink,
            ),    
      )
    ),
    ];
}  */

