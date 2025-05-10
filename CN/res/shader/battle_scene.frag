varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
    vec4 color = texture2D(CC_Texture0, v_texCoord);
    
    float alpha = (1 - v_fragmentColor.a);
    color.r = color.r * alpha + v_fragmentColor.r * v_fragmentColor.a;
    color.g = color.g * alpha + v_fragmentColor.g * v_fragmentColor.a;
    color.b = color.b * alpha + v_fragmentColor.b * v_fragmentColor.a;

    color.a = v_fragmentColor.a;

    gl_FragColor = color;
}

