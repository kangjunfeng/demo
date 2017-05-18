attribute vec4 Position;
attribute vec2 TextureCoords;
varying   vec2 TextureCoordsFrag;

varying vec4 vPosition;
uniform mat4 Matrix;



void main(void)
{
    gl_Position = Matrix * Position;
    TextureCoordsFrag = TextureCoords;
    vPosition = Position * Matrix;
}
