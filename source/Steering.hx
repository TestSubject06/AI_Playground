package;
import flash.geom.Matrix;
import flash.geom.Point;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import haxe.EnumFlags;

/**
 * ...
 * @author Zack
 */

enum SteeringBehavior {
	Seek;
	Flee;
	Arrive;
	Pursue;
	Evade;
	Wander;
	ObstacleAvoid;
	WallAvoid;
	Interpose;
	Hide;
	FollowPath;
	OffsetPursuit;
	Cohesion;
	Separation;
	Alignment;
}

@:enum
abstract Deceleration(Int) from Int to Int {
	var None = 0;
	var Slow = 1;
	var Medium = 2;
	var Fast = 3;
	
	@:op(A + B)
	public inline function add(n:Int):Int {
		return this + n;
	}
	
	@:op(A * B)
	public inline function mult(n:Int):Int {
		return this * n;
	}
}
 
class Steering
{
	private var activeBehaviors:EnumFlags<SteeringBehavior>;
	
	private var owner:Boid;
	private var evader:Boid;
	private var pursuer:Boid;
	
	private var maxSpeed:Float;
	private var maxForce:Float;
	
	private var seekPoint:FlxPoint;
	private var fleePoint:FlxPoint;
	private var arrivePoint:FlxPoint;
	
	private var wanderTarget:Vector2D;
	public var wanderRadius:Float = 30;
	public var wanderDistance:Float = 40;
	public var wanderJitterDistance:Float = 8.0;
	
	public var minDetectionBoxLength:Float = 40;
	
	private var arriveDecelerationRate:Deceleration;
	
	private var obstacles:Array<Obstacle>;
	
	public function new(boid:Boid, maxSpeed:Float, maxForce:Float) 
	{
		activeBehaviors = new EnumFlags<SteeringBehavior>();
		owner = boid;
		this.maxSpeed = maxSpeed;
		this.maxForce = maxForce;
		
		var theta:Float = Math.PI * 2 * Math.random();
		
		wanderTarget = new Vector2D(wanderRadius * Math.cos(theta), wanderRadius * Math.sin(theta));
	}
	
	public function isOn(behavior:SteeringBehavior):Bool {
		return activeBehaviors.has(behavior);
	}
	
	public function on(behavior:SteeringBehavior):Void {
		activeBehaviors.set(behavior);
	}
	
	public function off(behavior:SteeringBehavior):Void {
		activeBehaviors.unset(behavior);
	}
	
	public function allOff():Void {
		activeBehaviors = cast(activeBehaviors.toInt() & 0, EnumFlags<SteeringBehavior>);
	}
	
	public function calculateForce():Vector2D {
		var totalForces:Vector2D = new Vector2D();
		
		if (isOn(Seek)) {
			totalForces.add(seek(seekPoint));
		}
		
		if (isOn(Flee)) {
			totalForces.add(flee(fleePoint));
		}
		
		if (isOn(Arrive)) {
			totalForces.add(arrive(arrivePoint, arriveDecelerationRate));
		}
		
		if (isOn(Pursue)) {
			totalForces.add(pursue(evader));
		}
		
		if (isOn(Evade)) {
			totalForces.add(evade(pursuer));
		}
		
		if (isOn(Wander)) {
			totalForces.add(wander());
		}
		
		totalForces.truncate(maxForce);
		return totalForces;
	}
	
	private function seek(to:FlxPoint):Vector2D {
		var desiredVelocity:Vector2D = Vector2D.subtractV(Vector2D.fromFlxPoint(to), Vector2D.fromFlxPoint(owner.getMidpoint())).normalize().scale(maxSpeed);
		return Vector2D.subtractV(desiredVelocity, Vector2D.fromFlxPoint(owner.velocity)).scale(20);
	}
	
	private function flee(from:FlxPoint):Vector2D {
		var desiredVelocity:Vector2D = Vector2D.subtractV(Vector2D.fromFlxPoint(owner.getMidpoint()), Vector2D.fromFlxPoint(from)).normalize().scale(maxSpeed);
		return Vector2D.subtractV(desiredVelocity, Vector2D.fromFlxPoint(owner.velocity)).scale(20);
	}
	
	private function arrive(to:FlxPoint, deceleration:Deceleration):Vector2D {
		var toTarget:Vector2D = Vector2D.subtractV(Vector2D.fromFlxPoint(arrivePoint), Vector2D.fromFlxPoint(owner.getMidpoint()));
		var distance:Float = toTarget.length();
		
		if (distance > 0) {
			var speed = distance / (arriveDecelerationRate * 0.3);
			speed = Math.min(speed, maxSpeed);
			
			var desiredVelocity = toTarget.scale(speed / distance);
			var force = Vector2D.subtractV(desiredVelocity, Vector2D.fromFlxPoint(owner.velocity)).scale(20);
			return force;
		}
		return new Vector2D();
	}
	
	private function pursue(evader:Boid):Vector2D {
		var toEvader:Vector2D = Vector2D.fromFlxPoint(evader.getMidpoint()).subtract(Vector2D.fromFlxPoint(owner.getMidpoint()));
		var relativeHeading:Float = Vector2D.dot(owner.heading, evader.heading);
		
		if (Vector2D.dot(toEvader, owner.heading) > 0 && relativeHeading < -.95) {
			return seek(new FlxPoint(evader.x, evader.y));
		}
		
		var lookaheadTime:Float = toEvader.length() / (maxSpeed + Vector2D.fromFlxPoint(evader.velocity).length());
		lookaheadTime += turningTime(relativeHeading);
		return seek(Vector2D.toFlxPoint(Vector2D.fromFlxPoint(evader.velocity).scale(lookaheadTime).add(Vector2D.fromFlxPoint(evader.getMidpoint()))));
	}
	
	private function evade(pursuer:Boid):Vector2D {
		var toPursuer:Vector2D = Vector2D.fromFlxPoint(pursuer.getMidpoint()).subtract(Vector2D.fromFlxPoint(owner.getMidpoint()));
		
		var lookaheadTime:Float = toPursuer.length() / (maxSpeed + Vector2D.fromFlxPoint(pursuer.velocity).length());
		lookaheadTime += turningTime(Vector2D.dot(owner.heading, pursuer.heading));
		
		var evadeStrength:Float = Math.max(0, (400 - toPursuer.length()) / 2);
		return flee(Vector2D.toFlxPoint(Vector2D.fromFlxPoint(pursuer.velocity).scale(lookaheadTime).add(Vector2D.fromFlxPoint(pursuer.getMidpoint())))).scale(evadeStrength);
	}
	
	private function turningTime(relativeHeading:Float):Float {
		return ((relativeHeading - 1) * -Math.PI);
	}
	
	private function wander():Vector2D {
		wanderTarget
		.add(new Vector2D(FlxG.random.float( -1, 1) * wanderJitterDistance, FlxG.random.float( -1, 1) * wanderJitterDistance))
		.normalize()
		.scale(wanderRadius);
		
		var adjWanderTarget = Vector2D.addV(wanderTarget, new Vector2D(wanderDistance, 0));
		
		var rotationMatrix = new Matrix();
		rotationMatrix.rotate(owner.angle * FlxAngle.TO_RAD);
		rotationMatrix.translate(owner.x, owner.y);
		var worldSpacePoint:Point = rotationMatrix.transformPoint(new Point(adjWanderTarget.x, adjWanderTarget.y));
		
		return new Vector2D(worldSpacePoint.x, worldSpacePoint.y).subtract(Vector2D.fromFlxPoint(owner.getMidpoint())).scale(20);
	}
	
	public function obstacleAvoid(obstacles:Array<Obstacle>):Vector2D {
		var boxLength:Float = minDetectionBoxLength + ((Vector2D.fromFlxPoint(owner.velocity).length()/maxSpeed) * minDetectionBoxLength);
		
		return new Vector2D();
	}
	
	public function seekOn(point:FlxPoint):Void {
		seekPoint = point;
		on(Seek);
	}
	
	public function fleeOn(point:FlxPoint):Void {
		fleePoint = point;
		on(Flee);
	}
	
	public function arriveOn(point:FlxPoint, decelerationRate:Deceleration):Void {
		arrivePoint = point;
		arriveDecelerationRate = decelerationRate;
		on(Arrive);
	}
	
	public function pursueOn(evader:Boid):Void {
		this.evader = evader;
		on(Pursue);
	}
	
	public function evadeOn(pursuer:Boid):Void {
		this.pursuer = pursuer;
		on(Evade);
	}
	
	public function wanderOn():Void {
		on(Wander);
	}
	
	public function obstacleAvoidanceOn(obstacles:Array<Obstacle>):Void {
		this.obstacles = obstacles;
		on(ObstacleAvoid);
	}
}