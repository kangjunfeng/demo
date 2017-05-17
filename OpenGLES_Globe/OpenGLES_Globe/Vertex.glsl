attribute vec4 Position;
attribute vec2 TextureCoords;
varying   vec2 TextureCoordsFrag;

varying vec4 vPosition;
void main(void)
{
    gl_Position = Position;
    TextureCoordsFrag = TextureCoords;
    vPosition = Position;
}
