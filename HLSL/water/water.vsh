float fTime0_1;
float4 vViewPosition;
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
   float4 Position_PS : TEXCOORD0;
   float2 Texcoord : TEXCOORD1;
   float Id : TEXCOORD2;
   float3 Normal : TEXCOORD3;
   float3 Tangent : TEXCOORD4;
   float3 Binormal : TEXCOORD5;
   float3 ViewVec : TEXCOORD6;
};

#define row_count 256.0f
#define total_count 65536.0f
#define pi 3.1415926f
#define scale 100.0f
#define wave_amount 7
#define wave_size 0.02f
#define wave_speed 2.0f
#define drop_delay 0.1f
#define drop_size 50.0f
#define bell_curve_amount 10.0f

float random(float2 p)
{
   const float2 r = float2(23.1406926327792690f, 2.6651441426902251f);
   return frac(cos(fmod(123456789.0f, 1e-7 + 256.0f * dot(p,r))));
}

float bell_curve_approx(float x)
{
   float height = 0.5 * cos(2.0f * x) + 0.5f;
   return step(abs(2.0f * x), pi) * height;
}

void water_drop(float x, inout float y, float z, float offsetX, float offsetY, float offsetX_1, float offsetY_1, inout float aY, inout float bY, inout float cY)
{
   y += cos(drop_size * (length(float2(x - 0.5f, z - 0.5f)) - fTime0_1)) * bell_curve_approx((length(float2(x - 0.5f, z - 0.5f)) - fTime0_1 + drop_delay) * bell_curve_amount) * wave_size;
   
   aY += cos(drop_size * (length(float2(offsetX - 0.5f, offsetY - 0.5f)) - fTime0_1)) * bell_curve_approx((length(float2(offsetX - 0.5f, offsetY - 0.5f)) - fTime0_1 + drop_delay) * bell_curve_amount) * wave_size;
   bY += cos(drop_size * (length(float2(offsetX_1 - 0.5f, offsetY - 0.5f)) - fTime0_1)) * bell_curve_approx((length(float2(offsetX_1 - 0.5f, offsetY - 0.5f)) - fTime0_1 + drop_delay) * bell_curve_amount) * wave_size;
   cY += cos(drop_size * (length(float2(offsetX - 0.5f, offsetY_1 - 0.5f)) - fTime0_1)) * bell_curve_approx((length(float2(offsetX - 0.5f, offsetY_1 - 0.5f)) - fTime0_1 + drop_delay) * bell_curve_amount) * wave_size;
}

void getTangentSpace(VS_INPUT Input, float offsetX, float offsetY, float offsetX_1, float offsetY_1, float aY, float bY, float cY, inout float3 normal, inout float3 tangent, inout float3 binormal)
{
   float3 a = float3(offsetX, aY, offsetY); //0,0
   float3 b = float3(offsetX_1, bY, offsetY); //1,0
   float3 c = float3(offsetX, cY, offsetY_1); //0,1
   
   float3 aV_1 = c - a;
   float3 aV_2 = b - a;
   
   tangent = aV_2; //Use vector in direction of texcoord u
   binormal = aV_1; //Use vector in direction of texcoord v
   normal = cross(binormal, tangent); //Calculate correct normals
}

VS_OUTPUT vs_main(VS_INPUT Input)
{
   VS_OUTPUT Output;

   float id = Input.Position.z;
   float iteration = floor(id / row_count);
   
   float offsetX = (id - iteration * row_count) / row_count;
   float offsetX_1 = ((id + 1) - iteration * row_count) / row_count;
   float offsetY = iteration * 1.0f/row_count;
   float offsetY_1 = (iteration + 1) * 1.0f/row_count;
   
   float x = offsetX + 1.0f/row_count * Input.Texcoord.x;
   float z = offsetY + 1.0f/row_count * Input.Texcoord.y;
   float y = 0.0f;
   
   float aY = 0.0f; //Do required normal precalculation here in order to increase performance
   float bY = 0.0f;
   float cY = 0.0f;
   for(int i = 1; i <= wave_amount; i++)
   {
      for(int j = 1; j <= wave_amount; j++)
      {
         y += 1.0f / (i * j) * sin(2.0f * pi * (x * i + random(float2(i, j)) + fTime0_1 * wave_speed)) * sin(2.0f * pi * (z * j + random(float2(j, i)) + fTime0_1 * wave_speed)) * wave_size;
         
         aY += 1.0f / (i * j) * sin(2.0f * pi * (offsetX * i + random(float2(i, j)) + fTime0_1 * wave_speed)) * sin(2.0f * pi * (offsetY * j + random(float2(j, i)) + fTime0_1 * wave_speed)) * wave_size;
         bY += 1.0f / (i * j) * sin(2.0f * pi * (offsetX_1 * i + random(float2(i, j)) + fTime0_1 * wave_speed)) * sin(2.0f * pi * (offsetY * j + random(float2(j, i)) + fTime0_1 * wave_speed)) * wave_size;
         cY += 1.0f / (i * j) * sin(2.0f * pi * (offsetX * i + random(float2(i, j)) + fTime0_1 * wave_speed)) * sin(2.0f * pi * (offsetY_1 * j + random(float2(j, i)) + fTime0_1 * wave_speed)) * wave_size;
      }
   }
   
   water_drop(x, y, z, offsetX, offsetY, offsetX_1, offsetY_1, aY, bY, cY);
   
   float4 obj_pos = float4(x * scale - 0.5f * scale, y * scale, z * scale - 0.5f * scale, 1.0f);
   float4 view_pos = mul(obj_pos, matView);
   
   Output.Position = mul(view_pos, matProjection);
   Output.Position_PS = float4(obj_pos.xyz, y);
   Output.Texcoord = float2(x, 1.0f - z); //Recalculate texcoords
   Output.Id = id / total_count;
   
   //Tangent space
   getTangentSpace(Input, offsetX, offsetY, offsetX_1, offsetY_1, aY, bY, cY, Output.Normal, Output.Tangent, Output.Binormal);
   
   //Eye vector
   Output.ViewVec = normalize(view_pos);
   
   return Output;
}