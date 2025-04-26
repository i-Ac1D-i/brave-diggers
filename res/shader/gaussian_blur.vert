attribute vec4 a_position;
attribute vec2 a_texCoord;
attribute vec4 a_color;

#ifdef GL_ES
varying lowp vec4 v_fragmentColor;
varying lowp vec2 v_blurTexCoords[5];

const mediump float texelHeightOffset = 0.00176;
const mediump float texelWidthOffset = 0.003125;
#else
varying vec4 v_fragmentColor;
varying vec2 v_blurTexCoords[5];

const float texelHeightOffset = 0.00176;
const float texelWidthOffset = 0.003125;
#endif

void main()
{
    gl_Position = CC_PMatrix * a_position;
    v_fragmentColor = a_color;

    vec2 singleStepOffset = vec2(texelWidthOffset, texelHeightOffset);
    v_blurTexCoords[0] = a_texCoord.xy;
    v_blurTexCoords[1] = a_texCoord.xy + singleStepOffset * 1.407333;
    v_blurTexCoords[2] = a_texCoord.xy - singleStepOffset * 1.407333;
    v_blurTexCoords[3] = a_texCoord.xy + singleStepOffset * 3.294215;
    v_blurTexCoords[4] = a_texCoord.xy - singleStepOffset * 3.294215;
}
