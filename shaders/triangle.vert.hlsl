struct Input {
    uint VertexIndex : SV_VertexID;
    float3 Position : TEXCOORD0;
};

struct Output {
    float4 Color : TEXCOORD0;
    float4 Position : SV_Position;
};

static const float4 colors[3] = {
    float4(1.0f, 0.0f, 0.0f, 1.0f),
    float4(0.0f, 1.0f, 0.0f, 1.0f),
    float4(0.0f, 0.0f, 1.0f, 1.0f),
};

Output main(Input input) {
    Output output;

    output.Position = float4(input.Position, 1.0f);
    output.Color = colors[input.VertexIndex];

    return output;
};
