package {

import flash.display.Shape;
import flash.display.Bitmap;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.events.Event;
import flash.ui.Keyboard;

//  GameScreen
//
public class GameScreen extends Screen
{
  public static const NAME:String = "GameScreen";
  
  // Tile image:
  [Embed(source="../assets/tiles.png", mimeType="image/png")]
  private static const TilesImageCls:Class;
  private static const tilesimage:Bitmap = new TilesImageCls();

  // Text image:
  [Embed(source="../assets/text.png", mimeType="image/png")]
  private static const TextImageCls:Class;
  private static const textimage:Bitmap = new TextImageCls();
  
  /// Game-related functions

  private var scene:Scene;
  private var player:Player;
  private var visualizer:PlanVisualizer;

  public function GameScreen(width:int, height:int)
  {
    var tilesize:int = 16;
    scene = new Scene(width, height, tilesize, tilesimage.bitmapData);
    addChild(scene);

    player = new Player(scene);
    player.skin = createSkin(tilesize*1, tilesize*2, 0x44ff44);
    scene.add(player);

    visualizer = new PlanVisualizer(scene);
    addChild(visualizer);

    textimage.x = (width-textimage.width)/2;
    textimage.y = (height-textimage.height)/2;
  }

  // open()
  public override function open():void
  {
    var tilemap:TileMap = scene.createTileMap();
    tilemap.fillTile(0, 0, tilemap.width, tilemap.height, Tile.NONE);
    var i:int = 0;
    var p:Point;
    while (true) {
      var y:int = tilemap.height-i*3;
      if (y <= 1) break;
      for (var x:int = (i%2)*4; x < tilemap.width; x += 8) {
	tilemap.setTile(x+0, y, Tile.BLOCK);
	tilemap.setTile(x+1, y, Tile.BLOCK);
	tilemap.setTile(x+2, y, Tile.BLOCK);
	tilemap.setTile(x+3, y, Tile.BLOCK);
	p = new Point(x+3, y-1);
      }
      i++;
    }
    tilemap.goal = p;
    tilemap.setTile(tilemap.goal.x, tilemap.goal.y, Tile.GOAL);

    player.pos = scene.getTilePoint(0, tilemap.height-1);
    player.bounds = scene.getTileRect(0, tilemap.height-2, 1, 2);

    startUpdating(tilemap);
  }

  // close()
  public override function close():void
  {
  }

  // update()
  public override function update():void
  {
    updateMap();

    scene.update();
    scene.setCenter(player.pos, 100, 100);
    scene.paint();

    if (scene.tilemap.getCoordsByPoint(player.pos).equals(scene.tilemap.goal)) {
      dispatchEvent(new ScreenEvent(NAME));
    }
  }

  // keydown(keycode)
  public override function keydown(keycode:int):void
  {
    switch (keycode) {
    case Keyboard.LEFT:
    case 65:			// A
    case 72:			// H
      player.dir.x = -1;
      stopUpdating();
      break;

    case Keyboard.RIGHT:
    case 68:			// D
    case 76:			// L
      player.dir.x = +1;
      stopUpdating();
      break;

    case Keyboard.UP:
    case 87:			// W
    case 75:			// K
      player.dir.y = -1;
      stopUpdating();
      break;

    case Keyboard.DOWN:
    case 83:			// S
    case 74:			// J
      player.dir.y = +1;
      stopUpdating();
      break;

    case Keyboard.SPACE:
    case Keyboard.ENTER:
    case 88:			// X
    case 90:			// Z
      player.jump();
      stopUpdating();
      break;

    }
  }

  // keyup(keycode)
  public override function keyup(keycode:int):void 
  {
    switch (keycode) {
    case Keyboard.LEFT:
    case Keyboard.RIGHT:
    case 65:			// A
    case 68:			// D
    case 72:			// H
    case 76:			// L
      player.dir.x = 0;
      break;

    case Keyboard.UP:
    case Keyboard.DOWN:
    case 87:			// W
    case 75:			// K
    case 83:			// S
    case 74:			// J
      player.dir.y = 0;
      break;
    }
  }

  // createSkin(w, h, color)
  public static function createSkin(w:int, h:int, color:uint):Shape
  {
    var shape:Shape = new Shape();
    shape.graphics.beginFill(color);
    shape.graphics.drawRect(0, 0, w, h);
    shape.graphics.endFill();
    return shape;
  }

  private var _busy:Boolean;
  private var _mapqueue:Array;
  private const BEAM_SIZE:int = 10;

  private function startUpdating(tilemap:TileMap):void
  {
    if (_busy) return;

    addChild(textimage);
    _busy = true;
    _mapqueue = new Array();
    _mapqueue.push(tilemap);

    scene.tilemap = tilemap;
  }

  private function stopUpdating():void
  {
    if (!_busy) return;

    _busy = false;
    _mapqueue = null;
    removeChild(textimage);
    visualizer.update(null);
  }

  private function updateMap():void
  {
    if (!_busy) return;

    const N1:int = 8;

    var tilemap:TileMap;
    var n:int = _mapqueue.length;
    for (var i:int = 0; i < n; i++) {
      var x:int, y:int, w:int, h:int, dx:int, dy:int;
      var m:int = Math.floor(Math.random()*6);
      tilemap = _mapqueue[i].clone();
      switch (m) {
      case 0:
      case 1:
      // horizontal wall.
	w = (int)(Math.random()*N1);
	x = (int)(Math.random()*(tilemap.width-w));
	y = (int)(Math.random()*tilemap.height);
	for (dx = 0; dx < w; dx++) {
	  tilemap.setTile(x+dx, y, Tile.BLOCK);
	}
	break;
	
      case 2:
	// vertical wall.
	h = (int)(Math.random()*N1);
	x = (int)(Math.random()*tilemap.width);
	y = (int)(Math.random()*(tilemap.height-h));
	for (dy = 0; dy < h; dy++) {
	  tilemap.setTile(x, y+dy, Tile.BLOCK);
	}
	break;
	
      case 3:
	// vertical ladder.
	h = (int)(Math.random()*N1);
	x = (int)(Math.random()*tilemap.width);
	y = (int)(Math.random()*(tilemap.height-h));
	for (dy = 0; dy < h; dy++) {
	  tilemap.setTile(x, y+dy, Tile.LADDER);
	}
	break;

      default:
	// 4, 5
	// making a hole.
	w = (int)(Math.random()*N1);
	h = (int)(Math.random()*N1);
	x = (int)(Math.random()*(tilemap.width-w));
	y = (int)(Math.random()*(tilemap.height-h));
	for (dy = 0; dy < h; dy++) {
	  for (dx = 0; dx < w; dx++) {
	    tilemap.setTile(x+dx, y+dy, Tile.NONE);
	  }
	}
	break;
      }

      tilemap.plan = new PlanMap(tilemap, tilemap.goal, tilemap.bounds,
				 player.tilebounds, player.speed, 
				 player.jumpspeed, player.gravity);
      var action:PlanAction = tilemap.plan.fillPlan(tilemap.getCoordsByPoint(player.pos));
      if (action == null) continue;
      tilemap.score = action.cost;
      _mapqueue.push(tilemap);
    }

    _mapqueue.sortOn("score", Array.NUMERIC | Array.DESCENDING);
    if (BEAM_SIZE < _mapqueue.length) {
      _mapqueue.splice(BEAM_SIZE, _mapqueue.length-BEAM_SIZE);
    }
    if (0 < _mapqueue.length) {
      tilemap = _mapqueue[0];
      visualizer.update(tilemap.plan);
      scene.tilemap = tilemap;
      //Main.log("queue="+_mapqueue.length+", xscore="+tilemap.score);
    }
  }
}

} // package
