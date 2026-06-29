sampler2D TextureSampler : register(s0)
{
    Texture = (Texture);
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = Point;
    AddressU = Clamp;
    AddressV = Clamp;
};

float4 MainPS(float2 texCoord : TEXCOORD0) : COLOR0
{
    float4 color = tex2D(TextureSampler, texCoord);
    return color;
}

technique WaterReflection
{
    pass P0
    {
        PixelShader = compile ps_2_0 MainPS();
    }
}