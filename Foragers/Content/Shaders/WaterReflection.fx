sampler2D SpriteTexture : register(s0);

float4 PixelShaderFunction(float2 texCoord : TEXCOORD0, float4 color : COLOR0) : COLOR0
{
	float4 texColor = tex2D(SpriteTexture, texCoord);

	float alpha = texColor.a * color.a * (1.0 - texCoord.y);

	return float4(texColor.rgb, alpha);
}

technique WaterReflection
{
	pass Pass1
	{
		PixelShader = compile ps_2_0 PixelShaderFunction();
	}
}