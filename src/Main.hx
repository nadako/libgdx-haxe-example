import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.backends.lwjgl.LwjglApplication;
import com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

class MyGdxGame extends ApplicationAdapter {
	var batch:SpriteBatch;
	var img:Texture;

	@:overload
	override function create() {
		batch = new SpriteBatch();
		img = new Texture("assets/badlogic.jpg");
	}

	@:overload
	override function render() {
		Gdx.gl.glClearColor(1, 0, 0, 1);
		Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
		batch.begin();
		batch.draw(img, 0, 0);
		batch.end();
	}

	@:overload
	override function dispose() {
		batch.dispose();
		img.dispose();
	}
}

function main() {
	var config = new LwjglApplicationConfiguration();
	new LwjglApplication(new MyGdxGame(), config);
}
