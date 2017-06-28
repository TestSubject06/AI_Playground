package;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxSpriteUtil;

/**
 * ...
 * @author Zack
 */
class Obstacle extends FlxSprite
{
	public var radius:Float;
	public function new(x:Float, y:Float, radius:Float) 
	{
		super(x-radius-1, y-radius-1, null);
		//Make a circle graphic.
		makeGraphic(Math.ceil(radius * 2)+2, Math.ceil(radius * 2)+2, 0, true);
		FlxSpriteUtil.drawCircle(this, -1, -1, radius, 0, { thickness: 1, color:0xFFFFFFFF } );
		
		this.radius = radius;
	}
	
}