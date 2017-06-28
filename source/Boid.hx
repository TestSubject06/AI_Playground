package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxSpriteUtil;

/**
 * ...
 * @author Zack
 */
class Boid extends FlxSprite
{
	public var steering:Steering;
	public var heading:Vector2D;
	public var maxSpeed:Float = 200;
	public var maxForce:Float = 500;
	
	public function new(?X:Float=0, ?Y:Float=0) 
	{
		super(X, Y, AssetPaths.Boid__png);
		heading = new Vector2D(1, 0);
		
		steering = new Steering(this, maxSpeed, maxForce);
	}
	
	override public function update(elapsed:Float):Void 
	{	
		acceleration = Vector2D.toFlxPoint(steering.calculateForce());
		var oldVelocity:FlxPoint = new FlxPoint().copyFrom(velocity);
		
		//Process the acceleration
		super.update(elapsed);

		var velV = new Vector2D(velocity.x, velocity.y);
		if (velV.length() > maxSpeed) {
			velV.normalize().scale(maxSpeed);
		}
		velocity = Vector2D.toFlxPoint(velV);
		
		//Maximum turn-rate
		var newV:Vector2D = Vector2D.fromFlxPoint(velocity);
		var oldV:Vector2D = Vector2D.fromFlxPoint(oldVelocity);
		if (newV.lengthSquared() > 0.00001 || oldV.lengthSquared() > 0.00001) {
			if (Math.acos(Vector2D.dot(newV.normalize(), oldV.normalize())) > (Math.PI*2) * elapsed) {
				
				//Exceeded maximum turn rate
				//Use new velocity length, and old velocity direction
				var angle:Float = (Math.PI*2) * elapsed;
				if (Vector2D.dot(Vector2D.cross(Vector2D.fromFlxPoint(oldVelocity)), Vector2D.fromFlxPoint(velocity)) > 0){
					angle *= -1;
				}
				
				velocity = oldVelocity.scale(1 / FlxMath.vectorLength(oldVelocity.x, oldVelocity.y)).rotate(new FlxPoint(), angle*FlxAngle.TO_DEG).scale(FlxMath.vectorLength(velocity.x, velocity.y));
			}			
		}
			
		if (Math.abs(velocity.x) > 0.00001 && Math.abs(velocity.y) > 0.00001) {
			heading = Vector2D.fromFlxPoint(velocity).normalize();			
		}
	}
	
	override public function draw():Void 
	{
		angle = Math.atan2(heading.y, heading.x) * FlxAngle.TO_DEG;
		super.draw();
	}
	
}