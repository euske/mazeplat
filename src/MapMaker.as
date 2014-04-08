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
  private var _mapqueue:Array;	// Array of candidate maps.
  
  public function MapMaker(player:Player, tilemap:TileMap)
  {
    var p:Point = tilemap.findSpot(Tile.START);
    player.pos = tilemap.getTilePoint(p.x, p.y);
    player.bounds = tilemap.getTileRect(p.x, p.y-1, 1, 2);

    _player = player;
    _tilemap = tilemap;
    _mapqueue = new Array();
    _mapqueue.push(tilemap);
  }

  // tilemap: returns the current TileMap.
  public function get tilemap():TileMap
  {
    return _tilemap;
  }

  // update(): alter the map by one step.
  public function update():void
  {
    var hscale:int = HSCALE/2;
    var vscale:int = VSCALE;

    var queue:Array = new Array();
    for (var i:int = 0; i < _mapqueue.length && i < BEAM_SIZE; i++) {
      var tilemap:TileMap = _mapqueue[i];
      queue.push(tilemap);
      tilemap = tilemap.clone();

      var x:int, y:int, w:int, h:int, dx:int, dy:int;
      // Perform one of the following operations randomly:
      switch (rnd(7)) {
      case 0:
      case 1:
	// Add a random floor.
	w = (rnd(3)+1)*hscale;
	x = rnd((tilemap.width-w)/hscale)*hscale;
	y = rnd((tilemap.height)/vscale)*vscale;
	if (tilemap.goal.x < x || x+w <= tilemap.goal.x || tilemap.goal.y != y) {
	  for (dx = 0; dx < w; dx++) {
	    tilemap.setTile(x+dx, y, Tile.FLOOR);
	  }
	}
	break;
	
      case 2:
	// Add a random wall.
	h = vscale+1;
	x = rnd((tilemap.width)/hscale)*hscale;
	y = rnd((tilemap.height-h)/vscale)*vscale;
	if (tilemap.goal.x != x || tilemap.goal.y < y || y+h <= tilemap.goal.y) {
	  for (dy = 0; dy < h; dy++) {
	    tilemap.setTile(x, y+dy, Tile.WALL);
	  }
	}
	break;
	
      case 3:
      case 4:
	// Add a random ladder.
	h = (rnd(3)+1)*vscale;
	x = rnd(tilemap.width);
	y = rnd((tilemap.height-h)/vscale)*vscale;
	if (tilemap.goal.x != x || tilemap.goal.y < y || y+h <= tilemap.goal.y) {
	  for (dy = 0; dy < h; dy++) {
	    tilemap.setTile(x, y+dy, Tile.LADDER);
	  }
	}
	break;

      case 5:
	// Removing an existing floor.
	w = (rnd(4)+1)*hscale;
	h = (rnd(4)+1)*vscale;
	x = rnd((tilemap.width-w)/hscale)*hscale;
	y = rnd((tilemap.height-h)/vscale)*vscale;
	for (dy = 0; dy < h; dy++) {
	  for (dx = 0; dx < w; dx++) {
	    if (tilemap.getTile(x+dx, y+dy) == Tile.FLOOR) {
	      tilemap.setTile(x+dx, y+dy, Tile.NONE);
	    }
	  }
	}
	break;

      case 6:
	// Removing an existing ladder.
	w = (rnd(4)+1)*hscale;
	h = (rnd(4)+1)*vscale;
	x = rnd((tilemap.width-w)/hscale)*hscale;
	y = rnd((tilemap.height-h)/vscale)*vscale;
	for (dy = 0; dy < h; dy++) {
	  for (dx = 0; dx < w; dx++) {
	    if (tilemap.getTile(x+dx, y+dy) == Tile.LADDER) {
	      tilemap.setTile(x+dx, y+dy, Tile.NONE);
	    }
	  }
	}
	break;

      default:
	break;
      }

      // Try to find a path from the start to goal.
      tilemap.plan = new PlanMap(tilemap, tilemap.goal, tilemap.bounds,
				 _player.tilebounds, _player.speed, 
				 _player.jumpspeed, _player.gravity);
      if (tilemap.plan.fillPlan(tilemap.getCoordsByPoint(_player.pos))) {
	var cur:Point = tilemap.getCoordsByPoint(_player.pos);
	var action:PlanAction = tilemap.plan.getAction(cur.x, cur.y);
	if (action != null) {
	  // Found a path. Assign the score to this map.
	  tilemap.score = scoreAction(action)+scoreTiles(tilemap);
	  queue.push(tilemap);
	}
      }
    }

    // Sort the maps by its score.
    queue.sortOn("score", Array.NUMERIC | Array.DESCENDING);
    if (0 < queue.length) {
      _tilemap = queue[0];
    }
    Main.log("queue="+queue.length);
    _mapqueue = queue;
  }

  // rnd(n): generate random number 0...(n-1)
  private function rnd(n:int):int
  {
    return Math.floor(Math.random()*n);
  }

  // scoreTiles(tilemap): calculates the goodness of the given map.
  private function scoreTiles(tilemap:TileMap):int
  {
    var n:int = 0;
    for (var y:int = 0; y < tilemap.height; y++) {
      for (var x:int = 0; x < tilemap.width; x++) {
	// Different from the initial seed = good.
	var c:int = tilemap.getTile(x, y);
	switch (c) {
	case Tile.NONE:
	  if ((y % VSCALE) == 0) n++;
	  break;
	case Tile.FLOOR:
	  if ((y % VSCALE) != 0) n++;
	  break;
	case Tile.WALL:
	  n++;
	  break;
	case Tile.LADDER:
	  n--;
	  break;
	}
      }
    }
    return n;
  }

  // scoreAction(action): calculate the goodness of the given path.
  private function scoreAction(action:PlanAction):int
  {
    var walk:int = 0;
    var fall:int = 0;
    var climb:int = 0;
    var jump:int = 0;
    // more varied actions needed = good.
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
}

} // package
