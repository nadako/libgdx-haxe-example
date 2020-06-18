import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.backends.lwjgl.LwjglApplication;
import com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;

enum GameState {
	Start;
	Running;
	GameOver;
}

class PlaneGame extends ApplicationAdapter {
	static inline final PLANE_JUMP_IMPULSE:Single = 350;
	static inline final GRAVITY:Single = -20;
	static inline final PLANE_VELOCITY_X:Single = 200;
	static inline final PLANE_START_Y:Single = 240;
	static inline final PLANE_START_X:Single = 50;

	var shapeRenderer:ShapeRenderer;
	var batch:SpriteBatch;
	var camera:OrthographicCamera;
	var uiCamera:OrthographicCamera;
	var background:Texture;
	var ground:TextureRegion;
	var groundOffsetX:Single = 0;
	var ceiling:TextureRegion;
	var rock:TextureRegion;
	var rockDown:TextureRegion;
	var plane:Animation<TextureRegion>;
	var ready:TextureRegion;
	var gameOver:TextureRegion;
	var font:BitmapFont;

	var planePosition = new Vector2();
	var planeVelocity = new Vector2();
	var planeStateTime:Single = 0;
	var gravity = new Vector2();
	var rocks = new Array<Rock>();

	var gameState:GameState = Start;
	var score:Int = 0;
	var rect1 = new Rectangle();
	var rect2 = new Rectangle();

	var music:Music;
	var explode:Sound;

	@:overload
	override function create() {
		shapeRenderer = new ShapeRenderer();
		batch = new SpriteBatch();
		camera = new OrthographicCamera();
		camera.setToOrtho(false, 800, 480);
		uiCamera = new OrthographicCamera();
		uiCamera.setToOrtho(false, Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
		uiCamera.update();

		font = new BitmapFont(Gdx.files.internal("assets/arial.fnt"));

		background = new Texture("assets/background.png");
		ground = new TextureRegion(new Texture("assets/ground.png"));
		ceiling = new TextureRegion(ground);
		ceiling.flip(true, true);

		rock = new TextureRegion(new Texture("assets/rock.png"));
		rockDown = new TextureRegion(rock);
		rockDown.flip(false, true);

		var frame1 = new Texture("assets/plane1.png");
		frame1.setFilter(Linear, Linear);
		var frame2 = new Texture("assets/plane2.png");
		var frame3 = new Texture("assets/plane3.png");

		ready = new TextureRegion(new Texture("assets/ready.png"));
		gameOver = new TextureRegion(new Texture("assets/gameover.png"));

		// TODO: haxe doesn't support the variant with Rest<T> arguments for whatever reason
		plane = new Animation<TextureRegion>(0.05, java.NativeArray.make(new TextureRegion(frame1), new TextureRegion(frame2), new TextureRegion(frame3), new TextureRegion(frame2)));
		plane.setPlayMode(LOOP);

		music = Gdx.audio.newMusic(Gdx.files.internal("assets/music.mp3"));
		music.setLooping(true);
		music.play();

		explode = Gdx.audio.newSound(Gdx.files.internal("assets/explode.wav"));

		resetWorld();
	}

	function resetWorld() {
		score = 0;
		groundOffsetX = 0;
		planePosition.set(PLANE_START_X, PLANE_START_Y);
		planeVelocity.set(0, 0);
		gravity.set(0, GRAVITY);
		camera.position.x = 400;

		rocks.clear();
		for (i in 0...5) {
			var isDown = MathUtils.randomBoolean();
			rocks.add(new Rock(700 + i * 200, isDown ? 480 - rock.getRegionHeight() : 0, isDown ? rockDown : rock));
		}
	}

	function updateWorld() {
		var deltaTime = Gdx.graphics.getDeltaTime();
		planeStateTime += deltaTime;

		if (Gdx.input.justTouched()) {
			if (gameState == GameState.Start) {
				gameState = GameState.Running;
			}
			if (gameState == GameState.Running) {
				planeVelocity.set(PLANE_VELOCITY_X, PLANE_JUMP_IMPULSE);
			}
			if (gameState == GameState.GameOver) {
				gameState = GameState.Start;
				resetWorld();
			}
		}

		if (gameState != GameState.Start)
			planeVelocity.add(gravity);

		planePosition.mulAdd(planeVelocity, deltaTime);

		camera.position.x = planePosition.x + 350;
		if (camera.position.x - groundOffsetX > ground.getRegionWidth() + 400) {
			groundOffsetX += ground.getRegionWidth();
		}

		rect1.set(planePosition.x + 20, planePosition.y, plane.getKeyFrames()[0].getRegionWidth() - 20, plane.getKeyFrames()[0].getRegionHeight());
		for (r in rocks) {
			if (camera.position.x - r.position.x > 400 + r.image.getRegionWidth()) {
				var isDown = MathUtils.randomBoolean();
				r.position.x += 5 * 200;
				r.position.y = isDown ? 480 - rock.getRegionHeight() : 0;
				r.image = isDown ? rockDown : rock;
				r.counted = false;
			}
			rect2.set(r.position.x + (r.image.getRegionWidth() - 30) / 2 + 20, r.position.y, 20, r.image.getRegionHeight() - 10);
			if (rect1.overlaps(rect2)) {
				if (gameState != GameState.GameOver)
					explode.play();
				gameState = GameState.GameOver;
				planeVelocity.x = 0;
			}
			if (r.position.x < planePosition.x && !r.counted) {
				score++;
				r.counted = true;
			}
		}

		if (planePosition.y < ground.getRegionHeight() - 20
			|| planePosition.y + plane.getKeyFrames()[0].getRegionHeight() > 480 - ground.getRegionHeight() + 20) {
			if (gameState != GameState.GameOver)
				explode.play();
			gameState = GameState.GameOver;
			planeVelocity.x = 0;
		}
	}

	function drawWorld() {
		camera.update();
		batch.setProjectionMatrix(camera.combined);
		batch.begin();
		batch.draw(background, camera.position.x - background.getWidth() / 2, 0);
		for (rock in rocks) {
			batch.draw(rock.image, rock.position.x, rock.position.y);
		}
		batch.draw(ground, groundOffsetX, 0);
		batch.draw(ground, groundOffsetX + ground.getRegionWidth(), 0);
		batch.draw(ceiling, groundOffsetX, 480 - ceiling.getRegionHeight());
		batch.draw(ceiling, groundOffsetX + ceiling.getRegionWidth(), 480 - ceiling.getRegionHeight());
		batch.draw(plane.getKeyFrame(planeStateTime), planePosition.x, planePosition.y);
		batch.end();

		batch.setProjectionMatrix(uiCamera.combined);
		batch.begin();
		if (gameState == GameState.Start) {
			batch.draw(ready, Gdx.graphics.getWidth() / 2 - ready.getRegionWidth() / 2, Gdx.graphics.getHeight() / 2 - ready.getRegionHeight() / 2);
		}
		if (gameState == GameState.GameOver) {
			batch.draw(gameOver, Gdx.graphics.getWidth() / 2 - gameOver.getRegionWidth() / 2, Gdx.graphics.getHeight() / 2 - gameOver.getRegionHeight() / 2);
		}
		if (gameState == GameState.GameOver || gameState == GameState.Running) {
			font.draw(batch, "" + score, Gdx.graphics.getWidth() / 2, Gdx.graphics.getHeight() - 60);
		}
		batch.end();
	}

	@:overload
	override function render() {
		Gdx.gl.glClearColor(1, 0, 0, 1);
		Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

		updateWorld();
		drawWorld();
	}
}

private class Rock {
	public var position = new Vector2();
	public var image:TextureRegion;
	public var counted:Bool;

	public function new(x:Single, y:Single, image:TextureRegion) {
		this.position.x = x;
		this.position.y = y;
		this.image = image;
	}
}

function main() {
	var config = new LwjglApplicationConfiguration();
	config.width = 800;
	config.height = 480;
	new LwjglApplication(new PlaneGame(), config);
}
