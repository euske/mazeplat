package {

import flash.geom.Point;
import flash.geom.Rectangle;

//  MapMaker
//
public class MapMaker
{
  public const BEAM_SIZE:int = 4;

  private var _player:Player;
  private var _tilemap:TileMap;
  private var _mapqueue:Array;

  public function MapMaker(player:Player, tilemap:TileMap)
  {
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
    tilemap.setTile(0, tilemap.height-1, Tile.START);
    tilemap.setTile(tilemap.goal.x, tilemap.goal.y, Tile.GOAL);

    var p:Point = tilemap.findSpot(Tile.START);
    player.pos = tilemap.getTilePoint(p.x, p.y);
    player.bounds = tilemap.getTileRect(p.x, p.y-1, 1, 2);

    _player = player;
    _tilemap = tilemap;
    _mapqueue = new Array();
    _mapqueue.push(tilemap);
  }

  public function get tilemap():TileMap
  {
    return _tilemap;
  }

  public function update():void
  {
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
      case 4:
	// vertical ladder.
	h = (int)(Math.random()*N1+N1/2);
	x = (int)(Math.random()*tilemap.width);
	y = (int)(Math.random()*(tilemap.height-h));
	for (dy = 0; dy < h; dy++) {
	  tilemap.setTile(x, y+dy, Tile.LADDER);
	}
	break;

      default:
	// 5
	// making a hole.
	w = (int)(Math.random()*N1);
	h = (int)(Math.random()*N1);
	x = (int)(Math.random()*(tilemap.width-w));
	y = (int)(Math.random()*(tilemap.height-h));
	for (dy = 0; dy < h; dy++) {
	  for (dx = 0; dx < w; dx++) {
	    if (tilemap.getTile(x+dx, y+dy) == Tile.BLOCK) {
	      tilemap.setTile(x+dx, y+dy, Tile.NONE);
	    }
	  }
	}
	break;
      }

      tilemap.plan = new PlanMap(tilemap, tilemap.goal, tilemap.bounds,
				 _player.tilebounds, _player.speed, 
				 _player.jumpspeed, _player.gravity);
      if (!tilemap.plan.fillPlan(tilemap.getCoordsByPoint(_player.pos))) continue;
      var cur:Point = tilemap.getCoordsByPoint(_player.pos);
      var action:PlanAction = tilemap.plan.getAction(cur.x, cur.y);
      tilemap.score = action.cost;
      _mapqueue.push(tilemap);
    }

    _mapqueue.sortOn("score", Array.NUMERIC | Array.DESCENDING);
    if (BEAM_SIZE < _mapqueue.length) {
      _mapqueue.splice(BEAM_SIZE, _mapqueue.length-BEAM_SIZE);
    }
    if (0 < _mapqueue.length) {
      _tilemap = _mapqueue[0];
    }
    Main.log("queue="+_mapqueue.length);
  }
}

} // package
