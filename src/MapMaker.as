package {

import flash.geom.Point;
import flash.geom.Rectangle;

//  MapMaker
//
public class MapMaker
{
  public const BEAM_SIZE:int = 4;
  public const HSCALE:int = 4;
  public const VSCALE:int = 3;

  private var _player:Player;
  private var _tilemap:TileMap;
  private var _mapqueue:Array;
  
  public function MapMaker(player:Player, tilemap:TileMap)
  {
    tilemap.fillTile(0, 0, tilemap.width, tilemap.height, Tile.NONE);
    var a:Array;
    var i:int = 0;
    for (var y:int = tilemap.height-VSCALE; 2 <= y; y -= VSCALE) {
      a = new Array();
      for (var x:int = (i%2)*HSCALE; x < tilemap.width; x += HSCALE*2) {
	for (var dx:int = 0; dx < HSCALE; dx++) {
	  tilemap.setTile(x+dx, y, Tile.BLOCK);
	}
	a.push(new Point(x+HSCALE-1, y-1));
      }
      i++;
    }
    tilemap.goal = a[rnd(a.length)];
    tilemap.setTile(rnd(tilemap.width), tilemap.height-1, Tile.START);
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
  
  private function rnd(n:int):int
  {
    return Math.floor(Math.random()*n);
  }

  private function scoreTiles(tilemap:TileMap):int
  {
    var n:int = 0;
    for (var y:int = 0; y < tilemap.height; y++) {
      for (var x:int = 0; x < tilemap.width; x++) {
	var c:int = tilemap.getTile(x, y);
	if ((y % VSCALE) == 0) {
	  if (c == Tile.NONE) n++;
	} else {
	  if (c == Tile.BLOCK) n++;
	}
      }
    }
    return n;
  }

  private function scoreAction(action:PlanAction):int
  {
    var walk:int = 0;
    var fall:int = 0;
    var climb:int = 0;
    var jump:int = 0;
    while (action != null) {
      switch (action.type) {
      case PlanAction.WALK:
	walk++;
	break;
      case PlanAction.FALL:
	fall++;
	break;
      case PlanAction.CLIMB:
	climb++;
	break;
      case PlanAction.JUMP:
	jump++;
	break;
      }
      action = action.next;
    }
    return (walk+1)*(fall+1)*(jump+1)*(climb+1);
  }

  public function update():void
  {
    var tilemap:TileMap;
    var hscale:int = HSCALE/2;
    var vscale:int = VSCALE;

    var n:int = _mapqueue.length;
    for (var i:int = 0; i < n; i++) {
      tilemap = _mapqueue[i].clone();
      var x:int, y:int, w:int, h:int, dx:int, dy:int;
      switch (rnd(6)) {
      case 0:
      case 1:
	// horizontal wall.
	w = (rnd(3)+1)*hscale;
	x = rnd((tilemap.width-w)/hscale)*hscale;
	y = rnd((tilemap.height)/vscale)*vscale;
	for (dx = 0; dx < w; dx++) {
	  tilemap.setTile(x+dx, y, Tile.BLOCK);
	}
	break;
	
      case 2:
	// vertical wall.
	h = vscale;
	x = rnd((tilemap.width)/hscale)*hscale;
	y = rnd((tilemap.height-h)/vscale)*vscale;
	for (dy = 0; dy < h; dy++) {
	  tilemap.setTile(x, y+dy, Tile.BLOCK);
	}
	break;
	
      case 3:
      case 4:
	// vertical ladder.
	h = (rnd(3)+1)*vscale;
	x = rnd(tilemap.width);
	y = rnd((tilemap.height-h)/vscale)*vscale;
	for (dy = 0; dy < h; dy++) {
	  tilemap.setTile(x, y+dy, Tile.LADDER);
	}
	break;

      default:
	// 5
	// making a hole.
	w = (rnd(4)+1)*hscale;
	h = (rnd(4)+1)*vscale;
	x = rnd((tilemap.width-w)/hscale)*hscale;
	y = rnd((tilemap.height-h)/vscale)*vscale;
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
      if (action == null) continue;
      tilemap.score = scoreAction(action)+scoreTiles(tilemap);
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
