float4x4 matView;
float4x4 matProjection;

struct VS_INPUT 
{
   float4 Position : POSITION0;
   float2 Texcoord : TEXCOORD0;
};

struct VS_OUTPUT 
{
   float4 Position : POSITION0;
   float2 Texcoord : TEXCOORD0;
};

VS_OUTPUT vs_main( VS_INPUT Input )
{
   VS_OUTPUT Output;
   
   Output.Position = float4(Input.Position.xy, 0.0f, 1.0f);
   Output.Texcoord = float2(1.0f - Input.Texcoord.x, Input.Texcoord.y);
   
   return Output;
}