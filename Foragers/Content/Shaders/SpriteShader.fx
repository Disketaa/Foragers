sampler2D TextureSampler : register(s0);

float4 TintColor;
float Time;

void SpriteVertexShader(inout float4 color    : COLOR0,
                         inout float2 texCoord : TEXCOORD0,
                         inout float4 position : SV_Position)
{
}

float4 SpritePixelShader(float4 color    : COLOR0,
                          float2 texCoord : TEXCOORD0) : SV_Target0
{
    float4 texColor = tex2D(TextureSampler, texCoord);
    return texColor * color * TintColor;
}

technique SpriteBatch
{
    pass
    {
        VertexShader = compile vs_3_0 SpriteVertexShader();
        PixelShader  = compile ps_3_0 SpritePixelShader();
    }
}