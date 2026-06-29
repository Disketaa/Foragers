sampler2D SpriteTexture : register(s0);

float GradientHeight : register(c0);

float4 PixelShaderFunction(float2 texCoord : TEXCOORD0, float4 color : COLOR0) : COLOR0
{
	float4 texColor = tex2D(SpriteTexture, texCoord);

	float t = texCoord.y * GradientHeight;
	float alpha = texColor.a * color.a * lerp(0.5, 0.0, t);

	return float4(texColor.rgb, alpha);
}

technique WaterReflection
{
	pass Pass1
	{
		PixelShader = compile ps_2_0 PixelShaderFunction();
	}
}