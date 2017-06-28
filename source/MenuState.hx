package;

import flash.geom.Matrix;
import flash.geom.Point;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import Steering;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class MenuState extends FlxState
{
	var boid:Boid;
	var pointer:Boid;
	var wanderer:Boid;
	var bgCanvas:FlxSprite;
	var dot:FlxSprite;
	var boids:FlxTypedGroup<Boid>;
	var wanderTarget:Vector2D;
	override public function create():Void
	{
		super.create();
		
		bgCanvas = new FlxSprite(0, 0);
		bgCanvas.makeGraphic(FlxG.width, FlxG.height, 0x0, true);
		add(bgCanvas);
		
		boids = new FlxTypedGroup<Boid>();
		
		boid = new Boid(50, 50);
		boids.add(boid);
		
		var prey:Boid = new Boid(200, 200);
		prey.heading = new Vector2D( -1, 0);
		prey.color = 0xFF00FFFF;
		boids.add(prey);
		
		var chaser:Boid = new Boid(100, 100);
		chaser.heading = new Vector2D(2, -6).normalize();
		chaser.color = 0xFFFF0000;
		boids.add(chaser);
		
		wanderer = new Boid(250, 250);
		wanderer.heading = new Vector2D(2, -6).normalize();
		wanderer.color = 0xFFFFFF00;
		wanderer.steering.wanderOn();
		boids.add(wanderer);
		
		pointer = new Boid(FlxG.width / 2, FlxG.height / 2);
		pointer.heading = new Vector2D(1, 0);
		pointer.color = 0xFF888888;
		boids.add(pointer);
		
		chaser.steering.pursueOn(prey);
		prey.steering.evadeOn(chaser);
		prey.steering.seekOn(new FlxPoint(FlxG.width / 2, FlxG.height / 2));
		
		var wandr:Boid;
		for (i in 0...500) {
			wandr = new Boid(FlxG.random.int(0, FlxG.width), FlxG.random.int(0, FlxG.height));
			wandr.steering.wanderOn();
			wandr.color = FlxColor.fromHSB(FlxG.random.int(0, 360), 0.9, 1.0);
			boids.add(wandr);
		}
		
		add(boids);
		
		dot = new FlxSprite(0, 0);
		dot.makeGraphic(4, 4);
		add(dot);
		
		wanderTarget = new Vector2D(1, 0);
		
		var a = new Obstacle(400, 400, 30);
		add(a);
	}

	override public function update(elapsed:Float):Void
	{
		if (FlxG.mouse.justPressed) {
			boid.steering.allOff();
			if (FlxG.keys.pressed.CONTROL) {
				boid.steering.fleeOn(new FlxPoint(FlxG.mouse.x, FlxG.mouse.y));
			}else if(FlxG.keys.pressed.SHIFT){
				boid.steering.arriveOn(new FlxPoint(FlxG.mouse.x, FlxG.mouse.y), Deceleration.Slow);
			}else {
				boid.steering.seekOn(new FlxPoint(FlxG.mouse.x, FlxG.mouse.y));
			}
		}
		
		var angle:Float = Math.atan2(FlxG.mouse.y - pointer.y, FlxG.mouse.x - pointer.x);
		pointer.heading.x = Math.cos(angle);
		pointer.heading.y = Math.sin(angle);
		
		wanderTarget
		.add(new Vector2D(FlxG.random.float( -1, 1) * 6, FlxG.random.float( -1, 1) * 6))
		.normalize()
		.scale(30);
		
		var adjWanderTarget = Vector2D.addV(wanderTarget, new Vector2D(40, 0));
		
		var rotationMatrix = new Matrix();
		rotationMatrix.rotate(pointer.angle * FlxAngle.TO_RAD);
		rotationMatrix.translate(pointer.x, pointer.y);
		var worldSpacePoint:Point = rotationMatrix.transformPoint(new Point(adjWanderTarget.x, adjWanderTarget.y));
		
		dot.x = worldSpacePoint.x;
		dot.y = worldSpacePoint.y;
		
		boids.forEach(function(b:Boid) {
			if (b.x < 0) {
				b.x += FlxG.width;
			}
			if (b.x > FlxG.width) {
				b.x -= FlxG.width;
			}
			if (b.y < 0) {
				b.y += FlxG.height;
			}
			if (b.y > FlxG.height) {
				b.y -= FlxG.height;
			}
		}, false);
		
		var oldPoint:FlxPoint = wanderer.getMidpoint();
		super.update(elapsed);
		var newPoint:FlxPoint = wanderer.getMidpoint();
		//FlxSpriteUtil.drawRect(bgCanvas, 0, 0, FlxG.width, FlxG.height, 0x01000000);
		//FlxSpriteUtil.drawLine(bgCanvas, oldPoint.x, oldPoint.y, newPoint.x, newPoint.y, { thickness: 2, color: 0xFFFFFF00 } );
	}
}