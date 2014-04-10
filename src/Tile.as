package {

//  This class provides a set of functions that test 
//  if a block has a certain property.
// 
public class Tile
{
  public static const NONE:int = 0;
  public static const START:int = 1;
  public static const GOAL:int = 2;
  public static const FLOOR:int = 3;
  public static const WALL:int = 4;
  public static const LADDER:int = 5;

  // isNone(b): true if b is empty.
  public static var isNone:Function = 
    (function (b:int):Boolean { return b == NONE || b == START });

  // isObstacle(b): true if b is an obstacle.
  public static var isObstacle:Function = 
    (function (b:int):Boolean { return b < 0 || b == FLOOR || b == WALL; });

  // isStoppable(b): true if b blocks jumping/falling.
  public static var isStoppable:Function = 
    (function (b:int):Boolean { return b != NONE && b != START });

  // isGrabbable(b): true if b is a ladder.
  public static var isGrabbable:Function = 
    (function (b:int):Boolean { return b == LADDER; });

  // isGoal(b): true if b is goal.
  public static var isGoal:Function = 
    (function (b:int):Boolean { return b == GOAL; });

}

} // package
