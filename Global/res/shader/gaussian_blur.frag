varying vec4 v_fragmentColor;

varying vec2 v_blurTexCoords[5];

void main()
{
    vec4 sum = vec4(0.0, 0.0, 0.0, 0.0);
    sum += texture2D(CC_Texture0, v_blurTexCoords[0]) * 0.204164;
    sum += texture2D(CC_Texture0, v_blurTexCoords[1]) * 0.304005;
    sum += texture2D(CC_Texture0, v_blurTexCoords[2]) * 0.304005;
    sum += texture2D(CC_Texture0, v_blurTexCoords[3]) * 0.093913;
    sum += texture2D(CC_Texture0, v_blurTexCoords[4]) * 0.093913;

    gl_FragColor = sum;
}
