package {

import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;

//  Scene
// 
public class Scene extends Sprite
{
  private var _window:Rectangle;
  private var _tilesize:int;
  private var _tiles:BitmapData;
  private var _actors:Array;
  private var _mapimage:Bitmap;

  private var _tilemap:TileMap;
  private var _tilewindow:Rectangle;

  // Scene(width, height, tilemap)
  public function Scene(width:int, height:int, tilesize:int, tiles:BitmapData)
  {
    _window = new Rectangle(0, 0, width, height);
    _tilesize = tilesize;
    _tiles = tiles;
    _actors = new Array();
    _mapimage = new Bitmap(new BitmapData(width+tilesize, height+tilesize, 
					  true, 0x00000000));
    addChild(_mapimage);
  }

  // tilesize
  public function get tilesize():int
  {
    return _tilesize;
  }

  // tilemap
  public function get tilemap():TileMap
  {
    return _tilemap;
  }
  public function set tilemap(value:TileMap):void
  {
    _tilemap = value;
    _tilewindow = new Rectangle();
  }

  // window
  public function get window():Rectangle
  {
    return _window;
  }

  // add(actor)
  public function add(actor:Actor):void
  {
    _actors.push(actor);
    addChild(actor.skin);
  }

  // remove(actor)
  public function remove(actor:Actor):void
  {
    _actors.remove(actor);
    removeChild(actor.skin);
  }

  // update()
  public function update():void
  {
    for each (var actor:Actor in _actors) {
      actor.update();
    }
  }

  // paint()
  public function paint():void
  {
    for each (var actor:Actor in _actors) {
      var p:Point = translatePoint(actor.pos);
      actor.skin.x = p.x+actor.frame.x;
      actor.skin.y = p.y+actor.frame.y;
    }
    if (_tilemap != null) {
      var x0:int = Math.floor(_window.left/_tilesize);
      var y0:int = Math.floor(_window.top/_tilesize);
      var x1:int = Math.ceil(_window.right/_tilesize);
      var y1:int = Math.ceil(_window.bottom/_tilesize);
      var r:Rectangle = new Rectangle(x0, y0, x1-x0+1, y1-y0+1);
      if (!_tilewindow.equals(r)) {
	renderTiles(r);
      }
      _mapimage.x = (_tilewindow.x*_tilesize)-_window.x;
      _mapimage.y = (_tilewindow.y*_tilesize)-_window.y;
    }
  }

  // renderTiles(x, y)
  private function renderTiles(r:Rectangle):void
  {
    for (var dy:int = 0; dy <= r.height; dy++) {
      for (var dx:int = 0; dx <= r.width; dx++) {
	var i:int = _tilemap.getTile(r.x+dx, r.y+dy);
	if (0 <= i) {
	  var src:Rectangle = new Rectangle(i*_tilesize, 0, _tilesize, _tilesize);
	  var dst:Point = new Point(dx*_tilesize, dy*_tilesize);
	  _mapimage.bitmapData.copyPixels(_tiles, src, dst);
	}
      }
    }
    _tilewindow = r;
  }

  // setCenter(p)
  public function setCenter(p:Point, hmargin:int, vmargin:int):void
  {
    if (_tilemap != null) {
      // Center the window position.
      var mapwidth:int = _tilemap.width*_tilesize;
      var mapheight:int = _tilemap.height*_tilesize;
      if (mapwidth < _window.width) {
	_window.x = -(_window.width-mapwidth)/2;
      } else if (p.x-hmargin < _window.x) {
	_window.x = Math.max(0, p.x-hmargin);
      } else if (_window.x+_window.width < p.x+hmargin) {
	_window.x = Math.min(mapwidth, p.x+hmargin)-_window.width;
      }
      if (mapheight < _window.height) {
	_window.y = -(_window.height-mapheight)/2;
      } else if (p.y-vmargin < _window.y) {
	_window.y = Math.max(0, p.y-vmargin);
      } else if (_window.y+_window.height < p.y+vmargin) {
	_window.y = Math.min(mapheight, p.y+vmargin)-_window.height;
      }
    }
  }

  // translatePoint(p)
  public function translatePoint(p:Point):Point
  {
    return new Point(p.x-_window.x, p.y-_window.y);
  }

  // getCenteredBounds(center, margin)
  public function getCenteredBounds(center:Point, margin:int=0):Rectangle
  {
    var x0:int = Math.floor(_window.left/_tilesize);
    x0 = Math.max(x0-margin, 0);
    var y0:int = Math.floor(_window.top/_tilesize);
    y0 = Math.max(y0-margin, 0);
    var x1:int = Math.ceil(_window.right/_tilesize);
    x1 = Math.min(x1+margin, _tilemap.width-1);
    var y1:int = Math.ceil(_window.bottom/_tilesize);
    y1 = Math.min(y1+margin, _tilemap.height-1);
    return new Rectangle(x0, y0, x1-x0, y1-y0);
  }
}

} // package
