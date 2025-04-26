varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
    //原图没有alpha通道，所以大部分区域color.a为1
    //blendFunc = { GL_ONE, GL_ONE_MINUS_SRC_ALPHA }
    //blendFunc = { SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA }
    vec4 color = texture2D(CC_Texture0, v_texCoord);

    color.r += v_fragmentColor.r * color.a;
    color.g += v_fragmentColor.g * color.a;
    color.b += v_fragmentColor.b * color.a;
 
    color.a *= v_fragmentColor.a;

    /*
    color.r *= v_fragmentColor.a;
    color.g *= v_fragmentColor.a;
    color.b *= v_fragmentColor.a;
    */

    gl_FragColor = color;
}

