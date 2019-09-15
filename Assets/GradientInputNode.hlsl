void GradientInputNode_float (float4 BeginColor, float4 EndColor, out Gradient Out)
{
    Out.type = 0;

    Out.colorsLength = 2;
    Out.alphasLength = 2;

    Out.colors[0] = float4(BeginColor.r, BeginColor.g, BeginColor.b, 0.0f);
    Out.colors[1] = float4(EndColor.r, EndColor.g, EndColor.b, 50.0f);

    Out.alphas[0] = float2(BeginColor.a, 0.0f);
    Out.alphas[1] = float2(EndColor.a, 1.0f);

    Out.colors[2] = 0;
    Out.colors[3] = 0;
    Out.colors[4] = 0;
    Out.colors[5] = 0;
    Out.colors[6] = 0;
    Out.colors[7] = 0;

    Out.alphas[2] = 0;
    Out.alphas[3] = 0;
    Out.alphas[4] = 0;
    Out.alphas[5] = 0;
    Out.alphas[6] = 0;
    Out.alphas[7] = 0;
}

bool isfinite(Gradient g)
{
   return true;
}
