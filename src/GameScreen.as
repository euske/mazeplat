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

  // Map image:
  [Embed(source="../assets/map.png", mimeType="image/png")]
  private static const MapImageCls:Class;
  private static const mapimage:Bitmap = new MapImageCls();
  
  /// Game-related functions

  private var tilemap:TileMap;
  private var scene:Scene;
  private var player:Player;
  private var visualizer:PlanVisualizer;
  private var _busy:Boolean;

  public function GameScreen(width:int, height:int)
  {
    var tilesize:int = 16;
    tilemap = new TileMap(mapimage.bitmapData, tilesize);

    scene = new Scene(width, height, tilemap, tilesimage.bitmapData);
    addChild(scene);

    player = new Player(scene);
    player.pos = tilemap.getTilePoint(0, tilemap.height-1);
    player.bounds = tilemap.getTileRect(0, tilemap.height-2, 1, 2);
    player.skin = createSkin(tilesize*1, tilesize*2, 0x44ff44);
    scene.add(player);

    visualizer = new PlanVisualizer(scene);
    addChild(visualizer);
  }

  // open()
  public override function open():void
  {
    tilemap.fillTile(0, 0, tilemap.width, tilemap.height, Tile.NONE);
    var i:int = 0;
    var p:Point;
    while (true) {
      var y:int = tilemap.height-i*4;
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
    tilemap.setTile(p.x, p.y, Tile.GOAL);
    tilemap.goal = p;
    _busy = true;
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

  private function stopUpdating():void
  {
    _busy = false;
    visualizer.update(null);
  }

  private function updateMap():void
  {
    if (!_busy) return;

    tilemap.saveMap();
    var x:int, y:int, w:int, h:int, dx:int, dy:int;
    switch ((int)(Math.random()*4)) {
    case 1:
      // horizontal wall.
      w = (int)(Math.random()*10);
      x = (int)(Math.random()*(tilemap.width-w));
      y = (int)(Math.random()*tilemap.height);
      for (dx = 0; dx < w; dx++) {
	tilemap.setTile(x+dx, y, Tile.BLOCK);
      }
      break;

    case 2:
      // vertical wall.
      h = (int)(Math.random()*10);
      x = (int)(Math.random()*tilemap.width);
      y = (int)(Math.random()*(tilemap.height-h));
      for (dy = 0; dy < h; dy++) {
	tilemap.setTile(x, y+dy, Tile.BLOCK);
      }
      break;

    case 3:
      // vertical ladder.
      h = (int)(Math.random()*10);
      x = (int)(Math.random()*tilemap.width);
      y = (int)(Math.random()*(tilemap.height-h));
      for (dy = 0; dy < h; dy++) {
	tilemap.setTile(x, y+dy, Tile.LADDER);
      }
      break;

    default:
      // making a hole.
      w = (int)(Math.random()*10);
      h = (int)(Math.random()*10);
      x = (int)(Math.random()*(tilemap.width-w));
      y = (int)(Math.random()*(tilemap.height-h));
      for (dy = 0; dy < h; dy++) {
	for (dx = 0; dx < w; dx++) {
	  tilemap.setTile(x+dx, y+dy, Tile.NONE);
	}
      }
      break;
    }
    var plan:PlanMap = new PlanMap(tilemap, tilemap.goal, tilemap.bounds,
				   player.tilebounds, player.speed, 
				   player.jumpspeed, player.gravity);
    if (plan.fillPlan(tilemap.getCoordsByPoint(player.pos))) {
      visualizer.update(plan);
      tilemap.clearStack();
      scene.refreshTiles();
    } else {
      tilemap.restoreMap();
    }
  }

}

} // package
