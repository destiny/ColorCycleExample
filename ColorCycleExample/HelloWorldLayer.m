//
//  HelloWorldLayer.m
//  ColorCycleExample
//
//  Created by Chris Hill on 2/20/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "ColorSpaceUtilities.h"
#import "CCNode.h"
#import "CCAction.h"
#import "CCProtocols.h"

@interface HelloWorldLayer()

@property (nonatomic,retain) NSMutableArray* sprites;

-(void) addSpriteSheets;
-(void) addSprites;
-(void) startTinting;
-(void) tintIt:(CCNode*)node;

@end



/** Tints a CCNode that implements the CCNodeRGB protocol from current tint to a custom one.
 @warning This action doesn't support "reverse"
 @since v0.7.2
*/
@interface CCHSBTo : CCActionInterval <NSCopying>
{
	float _hueTo;
	float _saturationTo;
	float _brightnessTo;
	float _hueFrom;
	float _saturationFrom;
	float _brightnessFrom;
}
/** creates an action with duration and color */
+(id) actionWithDuration:(ccTime)duration  hue:(float)h saturation:(float)s brightness:(float)b;
/** initializes the action with duration and color */
-(id) initWithDuration:(ccTime)duration  hue:(float)h saturation:(float)s brightness:(float)b;
@end


// HelloWorldLayer implementation
@implementation HelloWorldLayer
@synthesize sprites = _sprites;

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {

		// [CH] Add our sprite sheets.
		[self addSpriteSheets];
		[self addSprites];
		[self startTinting];
	}
	return self;
}

/**
 * [CH] Define the graphics that we are using.
**/
- (void) addSpriteSheets 
{
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"sprites1.plist"];
}

/**
 * [CH] Create the sprites that we will use for our demo.
**/
-(void) addSprites
{
	self.sprites = [NSMutableArray arrayWithCapacity:5];

		// ask director the the window size
	CGSize size = [[CCDirector sharedDirector] winSize];

	float xInc = size.width / 4;
	float xPos = xInc;
	float yPos = size.height/ 3;

	/**
	 * [CH] Add 3 birds, then 3 pigs.
	**/
	for(int i=0;i<3;i++)
	{
		CCSprite* sprite = [CCSprite spriteWithSpriteFrameName:@"ghetto_bird.png"];
		sprite.position = ccp(xPos, yPos);
		int* foo = (int*)malloc(sizeof(int));
		*foo = 0;
		sprite.userData = foo;
		[self.sprites addObject:sprite];
		[self addChild:sprite];
		xPos += xInc;
	}

	yPos += yPos;
	xPos = xInc;


	for(int i=0;i<3;i++)
	{
		CCSprite* sprite = [CCSprite spriteWithSpriteFrameName:@"ghetto_pig.png"];
		sprite.position = ccp(xPos, yPos);
		int* foo = (int*)malloc(sizeof(int));
		*foo = 0;
		sprite.userData = foo;

		[self.sprites addObject:sprite];
		[self addChild:sprite];
		xPos += xInc;
	}
}

/**
 * [CH] Entry point into the tint code. Kickstarts the tinting on each node.
**/
-(void) startTinting
{
	for(CCSprite* sprite in self.sprites)
	{
		[self tintIt:sprite];
	}	
}

-(void) tintIt:(CCNode*)node
{
	float r,g,b; // [CH] Put the values in here.
	/**
	 * [CH] Hue is the color itself to use. This is a value between 0.0 and 1.0.
	 * Many color models/functions use a value between 0 and 360. This one
	 * does not. :D
	**/
	float hue = ((float)arc4random() / RAND_MAX); // [CH] between 0.0 and 1.0
	/**
	 * [CH] Saturation is how much color to add. 1.0 is 'maximum' color, and 
	 * will probably be *too* much color. Setting this to something sensible is
	 * a good idea.
	**/
	float saturation = 1.0;
	/**
	 * [CH] Brightness determines how much 'white' is mixed in. 
	 * Values <0.5 will be 'dimmed'.
	 * Values at 0.5 will provide max color saturation (if saturation is 1.0).
	 * Values >0.5 will wash out to white.
	 * Values at 1.0 are white, meaning that whatever is set for hue/saturation 
	 * are meaningless.
	**/
	float brightness = 0.5; // [CH] between 0.0 and 1.0. O.5 will provide full saturation. >
	HSL2RGB(hue, saturation, brightness, &r, &g, &b);

	/**
	 * [CH] Multiply the float values by 255.f to get a GLubyte that can be 
	 * used with OpenGL.
	**/
	GLubyte red = r * 255.f;
	GLubyte green = g * 255.f;
	GLubyte blue = b * 255.f;

	CCFiniteTimeAction* tintAction;
	/**
	 * [CH] Based upon the void pointer above, this will either use my crazy
	 * HSB action (experimental and weird looking), or the standard color tween.
	**/
	int* useHSB = (int*)node.userData;
	if(*useHSB)
	{
		tintAction = [CCHSBTo actionWithDuration:1 hue:hue saturation:saturation brightness:brightness];
	}else{
		tintAction = [CCTintTo actionWithDuration:1 red:red green:green blue:blue];
	}
	[node runAction:
		[CCSequence actions:
			tintAction,
			[CCCallFuncN actionWithTarget:self selector:@selector(tintIt:)],
		nil]
	];
	
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	for(CCSprite* sprite in self.sprites){
		free(sprite.userData);
	}
	self.sprites = nil;
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end

//
// TintTo
//
#pragma mark -
#pragma mark TintTo
@implementation CCHSBTo
+(id) actionWithDuration:(ccTime)t hue:(float)h saturation:(float)s brightness:(float)b
{
	return [[[ self alloc] initWithDuration:t hue:h saturation:s brightness:b] autorelease];
}

-(id) initWithDuration: (ccTime) t hue:(float)h saturation:(float)s brightness:(float)b
{
	if( (self=[super initWithDuration:t] ) )
	{
		_hueTo = h;
		_saturationTo = s;
		_brightnessTo = b;
	}
			
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	CCAction *copy = [[[self class] allocWithZone: zone] initWithDuration:[self duration] hue:_hueTo saturation:_saturationTo brightness:_brightnessTo];
	return copy;
}

-(void) startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];
	
	id<CCRGBAProtocol> tn = (id<CCRGBAProtocol>) target_;
	ccColor3B from_ = [tn color];
	float r = from_.r / 255.f;
	float g = from_.g / 255.f;
	float b = from_.b / 255.f;
	
	RGB2HSL(r,g,b, &_hueFrom, &_saturationFrom, &_brightnessFrom);
	_brightnessFrom = 0.5;
}

-(void) update: (ccTime) t
{
	id<CCRGBAProtocol> tn = (id<CCRGBAProtocol>) target_;
	float h = _hueFrom + (_hueTo - _hueFrom) * t;
	float s = _saturationFrom + (_saturationTo - _saturationFrom) * t;
	float b = _brightnessFrom + (_brightnessTo - _brightnessFrom) * t;
	float r,g,_b;
	HSL2RGB(h, s, b, &r, &g, &_b);

	[tn setColor:ccc3((GLubyte)(r * 255.f), (GLubyte)(g * 255.f), (GLubyte)(_b * 255.f))];
}
@end
