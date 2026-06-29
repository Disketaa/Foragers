sampler2D TextureSampler : register(s0)
{
    Texture = (Texture);
    AddressU = Clamp;
    AddressV = Clamp;
};

float4 MainPS(float2 texCoord : TEXCOORD0) : COLOR0
{
    float2 reflectedCoord = float2(texCoord.x, 1.0 - texCoord.y);
    float4 color = tex2D(TextureSampler, reflectedCoord);
    return color;
}

technique WaterReflection
{
    pass P0
    {
        PixelShader = compile ps_2_0 MainPS();
    }
}