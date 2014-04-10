package {

import flash.display.Shape;
import flash.display.Bitmap;
import flash.geom.Point;
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
  private var _maker:MapMaker;

  public function GameScreen(width:int, height:int, scale:int=2)
  {
    var tilesize:int = 16;
    scene = new Scene(width/scale, height/scale, tilesize, tilesimage.bitmapData);
    scene.width *= scale;
    scene.height *= scale;
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

    var p:Point = tilemap.findSpot(Tile.START);
    player.pos = tilemap.getTilePoint(p.x, p.y);
    player.bounds = tilemap.getTileRect(p.x, p.y-1, 1, 2);
    startUpdating(tilemap);
    scene.tilemap = tilemap;
  }

  // close()
  public override function close():void
  {
  }

  // update()
  public override function update():void
  {
    if (_maker != null) {
      _maker.update();
      visualizer.update(_maker.tilemap.plan);
      scene.tilemap = _maker.tilemap;
      Main.log("score="+_maker.tilemap.score);
    }

    scene.update();
    scene.setCenter(player.pos, 100, 100);
    scene.paint();

    if (0 < scene.tilemap.scanTileByRect(player.bounds, Tile.isGoal).length) {
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

  private function startUpdating(tilemap:TileMap):void
  {
    if (_maker == null) {
      addChild(textimage);
      _maker = new MapMaker(player, tilemap, tilemap.findSpot(Tile.GOAL));
    }
  }

  private function stopUpdating():void
  {
    if (_maker != null) {
      scene.tilemap = _maker.tilemap;
      _maker = null;
      removeChild(textimage);
      visualizer.update(null);
    }
  }
}

} // package
