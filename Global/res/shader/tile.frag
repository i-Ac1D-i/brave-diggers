varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
    vec4 color = texture2D(CC_Texture0, fract(v_texCoord));
    gl_FragColor = color;
}

