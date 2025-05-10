varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
    vec4 color = texture2D(CC_Texture0, v_texCoord);
    float grayscale = dot(color.rgb, vec3(0.3, 0.59, 0.11));
    color.r = grayscale;
    color.g = grayscale;
    color.b = grayscale;

    gl_FragColor = color;
}

