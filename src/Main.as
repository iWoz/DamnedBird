package
{
	import com.coreyoneil.collision.CollisionList;
	import com.greensock.TweenLite;
	import com.greensock.easing.Quart;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	public class Main extends Sprite
	{
		public static const SCENE_HEIGHT:uint = 200;
		public static const SCENE_WIDTH:uint = 300;
		public static const PILLAR_WIDTH:uint = 30;
		public static const PILLAR_GAP:uint = 100;
		public static const MIN_HOLE_WIDTH:uint = 44;
		public static const GROUND_HEIGHT:uint = SCENE_HEIGHT - 8;
		public static const MAX_SCORE_KEY:String = "maxScoreKey";
		
		private var canvas:Sprite;
		private var pillarLayer:Sprite;
		private var bird:Sprite;
		private var scoreTf:TextField;
		
		private var maxS:SharedObject;
		private var score:uint = 0;
		private var maxScore:uint = 0;
		private var died:Boolean; 
		
		private var colList:CollisionList;
		
		private var pillarX:Number = 0;

		public function Main()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			setContextMenu();
			
			canvas = new Sprite;
			canvas.graphics.beginFill( 0xcccccc );
			canvas.graphics.drawRect( 0, 0, SCENE_WIDTH, SCENE_HEIGHT );
			canvas.graphics.endFill();
			addChild( canvas );
			
			canvas.x = (stage.stageWidth - canvas.width) * 0.5;
			canvas.y = (stage.stageHeight - canvas.height) * 0.5;
			trace( canvas.x, canvas.y );
			
			pillarLayer = new Sprite;
			canvas.addChild( pillarLayer );
			
			bird = new Sprite;
			bird.graphics.beginFill( 0xff0000 );
			bird.graphics.drawCircle( 0, 0, 8 );
			bird.graphics.endFill();
			bird.x = 50;
			bird.y = 100;
			canvas.addChild( bird );
			
			colList = new CollisionList( bird );
			
			var mask:Sprite = new Sprite;
			mask.graphics.beginFill(0);
			mask.graphics.drawRect( 0, 0, canvas.width, canvas.height );
			mask.graphics.endFill();
			canvas.addChild( mask );
			pillarLayer.mask = mask;
			for( var i:uint = 0; i < 4; i++ )
			{
				var p:Sprite = getPillarPair();
				p.x = pillarX = PILLAR_GAP * (i+1);
				pillarLayer.addChild( p );
				colList.addItem( p );
			}
			
			maxS = SharedObject.getLocal(MAX_SCORE_KEY);
			if( maxS )
			{
				maxScore = uint(maxS.data["max"]);
			}
			
			scoreTf = new TextField;
			scoreTf.selectable = false;
			scoreTf.width = SCENE_WIDTH;
			scoreTf.text = "点击鼠标或按任意键使红点上升，点击画布开始游戏。。。"
			scoreTf.x = 0;
			scoreTf.y = -20;
			canvas.addChild(scoreTf);
			
			addEventListener(MouseEvent.CLICK, function startHandler(e:MouseEvent):void
			{
				removeEventListener(MouseEvent.CLICK, arguments.callee);
				addEventListener(Event.ENTER_FRAME, updateHandler);
				addEventListener(MouseEvent.CLICK, clickHandler);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, clickHandler);
				TweenLite.to( bird, 1, { delay:0.5, y:GROUND_HEIGHT, ease:Quart.easeIn } );
				scoreTf.text = "分数："+score+" 最高分："+maxScore;
			});
			stage.addEventListener(Event.RESIZE, function(e:Event):void
			{
				canvas.x = (stage.stageWidth - canvas.width) * 0.5;
				canvas.y = (stage.stageHeight - canvas.height) * 0.5;
			});
		}
		
		private function clickHandler( e:Event ):void
		{
			trace("clicked");
			TweenLite.killTweensOf( bird );
			bird.y -= 10;
			TweenLite.to( bird, 1, { delay:0, y:GROUND_HEIGHT, ease:Quart.easeIn } );
		}
		
		private function updateHandler( e:Event ):void
		{
			if( !died )
			{
				pillarLayer.x -= 1;
				if( pillarLayer.x % PILLAR_GAP == 0 )
				{
					if( ++score > maxScore )
					{
						maxScore = score;
					}
					scoreTf.text = "分数："+score+" 最高分："+maxScore;
					var p:Sprite = getPillarPair();
					p.x = pillarX += PILLAR_GAP;
					pillarLayer.addChild( p );
					colList.addItem( p );
				}
			}
			if( colList.checkCollisions().length > 0 || bird.y >= GROUND_HEIGHT )
			{
				died = true;
				removeEventListener(Event.ENTER_FRAME, updateHandler);
				removeEventListener(MouseEvent.CLICK, clickHandler);
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, clickHandler);
				scoreTf.text = "分数："+score+" 最高分："+maxScore+" 挂了。。。按任意键继续。。";
				maxS.data["max"] = maxScore;
				maxS.flush();
				colList.dispose();
				colList.addItem(bird);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, function restart(e:KeyboardEvent):void
				{
					stage.removeEventListener(KeyboardEvent.KEY_DOWN, arguments.callee);
					died = false;
					bird.x = 50;
					bird.y = 100;
					score = 0;
					scoreTf.text = "分数："+score+" 最高分："+maxScore;
					pillarLayer.removeChildren();
					pillarLayer.x = 0;
					for( var i:uint = 0; i < 4; i++ )
					{
						var p:Sprite = getPillarPair();
						p.x = pillarX = PILLAR_GAP * (i+1);
						pillarLayer.addChild( p );
						colList.addItem( p );
					}
					addEventListener(Event.ENTER_FRAME, updateHandler);
					addEventListener(MouseEvent.CLICK, clickHandler);
					stage.addEventListener(KeyboardEvent.KEY_DOWN, clickHandler);
					
					TweenLite.to( bird, 1, { delay:0.5, y:GROUND_HEIGHT, ease:Quart.easeIn } );
				});
			}
		}
		
		public function getPillarPair():Sprite
		{
			var p:Sprite = new Sprite;
			var topH:Number = Math.random() * (SCENE_HEIGHT - MIN_HOLE_WIDTH);
			var topP:Shape = getPillar( topH );
			var holeW:Number = Math.random() * (SCENE_HEIGHT - topH - MIN_HOLE_WIDTH) + MIN_HOLE_WIDTH;
			var bottomH:Number = SCENE_HEIGHT - topH - holeW;
			var bottomP:Shape = getPillar( bottomH );
			p.addChild( topP );
			p.addChild( bottomP );
			bottomP.y = topH + holeW;
			return p;
		}
		
		public function getPillar( height:Number ):Shape
		{
			var p:Shape = new Shape;
			p.graphics.beginFill( 0x00ff00 );
			p.graphics.drawRect( 0, 0, PILLAR_WIDTH, height );
			p.graphics.endFill();
			return p;			
		}
		
		private function setContextMenu():void
		{
			this.contextMenu = new ContextMenu();
			this.contextMenu.hideBuiltInItems();
			this.contextMenu.builtInItems.quality = true;
			
			var szItem:ContextMenuItem = new ContextMenuItem( "山寨自Flappy Bird..." );
			this.contextMenu.customItems.push( szItem );
			var authorItem:ContextMenuItem = new ContextMenuItem( "Author:吴智炜(Tim Wu)" );
			this.contextMenu.customItems.push( authorItem );
			authorItem.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function (e:ContextMenuEvent):void
			{
				navigateToURL( new URLRequest("http://wuzhiwei.net/about"), "_blank" );
			});
		}
		
	}
}