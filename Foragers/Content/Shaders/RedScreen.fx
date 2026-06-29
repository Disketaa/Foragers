float4 MainPS(float4 color : COLOR0) : COLOR0
{
    return float4(1.0, 0.0, 0.0, 1.0);
}

technique RedScreen
{
    pass P0
    {
        PixelShader = compile ps_2_0 MainPS();
    }
}