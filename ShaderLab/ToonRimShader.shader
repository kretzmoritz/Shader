// Coded by Moritz Kretz
// Edited: 2/4/2012

Shader "ToonRimShader"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_OutlineDistance("Outline distance", Float) = 7.5
		_OutlineSize ("Outline width", Float) = 0.0025
		_OutlineColor ("Outline Color", Color) = (0,0,0,1)
		_MainTex ("Texture", 2D) = "white" {}
		_BumpMap ("Bumpmap", 2D) = "bump" {}
		_RampTex ("Shading Ramp", 2D) = "gray" {}
		_SpecularTex ("Specular Level (R) Gloss (G)", 2D) = "gray" {}
		_RimPower ("Rim Power", Float) = 3.0
		_Cutoff ("Alphatest Cutoff", Float) = 0.5
	}
	
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		
		CGPROGRAM
			#pragma surface surf ToonRimShader alphatest:_Cutoff
			#pragma target 3.0
			
			struct Input
			{
				float2 uv_MainTex;
				float2 uv_BumpMap;
				float3 viewDir;
			};
			
			sampler2D _MainTex, _BumpMap, _RampTex, _SpecularTex;
			
			float _RimPower;
			
			half4 LightingToonRimShader (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
			{
				half3 h = normalize (lightDir + viewDir);
				
				half NdotL = dot (s.Normal, lightDir);
				half diff = NdotL * 0.5 + 0.5;
				
				half3 ramp = tex2D(_RampTex, float2(diff * atten)).rgb;
				
				float nh = max (0, dot (s.Normal, h));
				float spec = pow (nh, 50.0 * s.Gloss) * s.Specular;
				
				half4 c;
				c.rgb = (s.Albedo * (_LightColor0.rgb * diff * ramp) + (_LightColor0.rgb * spec)) * (atten * 2);
				c.a = s.Alpha;
				return c;
			}
			
			void surf (Input IN, inout SurfaceOutput o)
			{
				o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
				o.Alpha = tex2D(_MainTex, IN.uv_MainTex).a;
				o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));
				
				float3 specMap = tex2D(_SpecularTex, IN.uv_MainTex).rgb;
				o.Specular = specMap.r;
				o.Gloss = specMap.g;
				
				half rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
				o.Emission = pow (rim, _RimPower) * tex2D(_MainTex, IN.uv_MainTex).rgb;
			}
			
		ENDCG
		
		Pass
		{
			Name "Outline"
			Tags { "LightMode" = "Always" "Queue" = "Overlay" }
			
			Cull Front
			ZWrite On
			ZTest LEqual
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha
			Offset 15, 15
			
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
				
				struct appdata
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
				};
				
				struct v2f
				{
					float4 pos : POSITION;
					float4 color : COLOR;
				};
				
				uniform float _OutlineDistance;
				uniform float _OutlineSize;
				uniform float4 _OutlineColor;
				
				v2f vert(appdata v)
				{
					v2f o;
					o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
					
					float3 norm = mul ((float3x3)UNITY_MATRIX_IT_MV, v.normal);
					float2 offset = TransformViewToProjection(norm.xy);
					
					if(o.pos.z <= _OutlineDistance)
					{
						o.pos.xy += offset * o.pos.z * _OutlineSize;
					}
					else
					{
						o.pos.xy += offset * _OutlineSize;
					}
					
					o.color = _OutlineColor;
					return o;
				}
				
				half4 frag(v2f i) : COLOR { return i.color; }
				
			ENDCG
	   }
	}
	
	Fallback "Transparent/Cutout/Diffuse"
}