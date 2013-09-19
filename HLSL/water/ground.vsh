float4x4 matView;
float4x4 matProjection;

struct VS_INPUT
{
   float4 Position : POSITION0;
   float2 Texcoord : TEXCOORD0;
   float4 Normal : NORMAL0;
   float4 Tangent : TANGENT0;
   float4 Binormal : BINORMAL0;
};

struct VS_OUTPUT
{
   float4 Position : POSITION0;
   float4 Position_PS : TEXCOORD0;
   float2 Texcoord : TEXCOORD1;
   float4 Normal : TEXCOORD2;
   float4 Tangent : TEXCOORD3;
   float4 Binormal : TEXCOORD4;
};

#define vertex_scale 0.25f
#define height_scale 0.5f
#define height_offset -50.0f

VS_OUTPUT vs_main(VS_INPUT Input)
{
   VS_OUTPUT Output;

   float3 temp_position = float3(Input.Position.x, Input.Position.y * height_scale + height_offset, Input.Position.z);
   Output.Position = mul(mul(float4(temp_position * vertex_scale, 1.0f), matView), matProjection);
   Output.Position_PS = float4(temp_position * vertex_scale, 1.0f);
   Output.Texcoord = Input.Texcoord;
   Output.Normal = Input.Normal;
   Output.Tangent = Input.Tangent;
   Output.Binormal = Input.Binormal;
   
   return Output;
}