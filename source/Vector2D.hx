package;
import flixel.math.FlxPoint;

/**
 * ...
 * @author Zack
 */
class Vector2D {
	
	public static function fromFlxPoint(point:FlxPoint):Vector2D {
		return new Vector2D(point.x, point.y);
	}
	
	public static function toFlxPoint(vector:Vector2D):FlxPoint {
		return new FlxPoint(vector.x, vector.y);
	}
	
	public static function dot(a:Vector2D, b:Vector2D):Float {
		return a.x * b.x + a.y + b.y;
	}
	
	public static function cross(v:Vector2D):Vector2D {
		return new Vector2D(v.y, -v.x);
	}
	
	public static function add(a:Vector2D, b:Vector2D):Vector2D {
		return new Vector2D(a.x + b.x, a.y + b.y);
	}
	
	public static function subtract(a:Vector2D, b:Vector2D):Vector2D {
		return new Vector2D(a.x - b.x, a.y - b.y);
	}
	
	public static function scale(v:Vector2D, s:Float):Vector2D {
		return new Vector2D(v.x * s, v.y * s);
	}
	
	public var x:Float;
	public var y:Float;
	
	public function new(?x:Float=0, ?y:Float=0) {
		this.x = x;
		this.y = y;
	}
	
	public function length():Float{
		return Math.sqrt(x*x + y*y);
	}
	
	public function lengthSquared():Float {
		return x * x + y * y;
	}
	
	public function scale(s:Float):Vector2D {
		x *= s;
		y *= s;
		return this;
	}
	
	public function normalize():Vector2D {
		var l = length();
		x /= l;
		y /= l;
		return this;
	}
	
	public function add(v:Vector2D):Vector2D {
		x += v.x;
		y += v.y;
		return this;
	}
	
	public function subtract(v:Vector2D):Vector2D {
		x -= v.x;
		y -= v.y;
		return this;
	}
	
}