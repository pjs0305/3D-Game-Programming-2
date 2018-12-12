struct MATERIAL
{
	float4					m_cAmbient;
	float4					m_cDiffuse;
	float4					m_cSpecular; //a = power
	float4					m_cEmissive;
};

cbuffer cbCameraInfo : register(b1)
{
	matrix		gmtxView : packoffset(c0);
	matrix		gmtxProjection : packoffset(c4);
	float3		gvCameraPosition : packoffset(c8);
};

cbuffer cbGameObjectInfo : register(b2)
{
	matrix		gmtxGameObject : packoffset(c0);
	MATERIAL	gMaterial : packoffset(c4);
	uint		gnTexturesMask : packoffset(c8);
};

#include "Light.hlsl"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//#define _WITH_VERTEX_LIGHTING

#define MATERIAL_ALBEDO_MAP			0x01
#define MATERIAL_SPECULAR_MAP		0x02
#define MATERIAL_NORMAL_MAP			0x04
#define MATERIAL_METALLIC_MAP		0x08
#define MATERIAL_EMISSION_MAP		0x10
#define MATERIAL_DETAIL_ALBEDO_MAP	0x20
#define MATERIAL_DETAIL_NORMAL_MAP	0x40

Texture2D gtxtAlbedoTexture : register(t6);
Texture2D gtxtSpecularTexture : register(t7);
Texture2D gtxtNormalTexture : register(t8);
Texture2D gtxtMetallicTexture : register(t9);
Texture2D gtxtEmissionTexture : register(t10);
Texture2D gtxtDetailAlbedoTexture : register(t11);
Texture2D gtxtDetailNormalTexture : register(t12);

SamplerState gssWrap : register(s0);

struct VS_STANDARD_INPUT
{
	float3 position : POSITION;
	float2 uv : TEXCOORD;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;
	float3 bitangent : BITANGENT;
};

struct VS_STANDARD_OUTPUT
{
	float4 position : SV_POSITION;
	float3 positionW : POSITION;
	float3 normalW : NORMAL;
	float3 tangentW : TANGENT;
	float3 bitangentW : BITANGENT;
	float2 uv : TEXCOORD;
};

VS_STANDARD_OUTPUT VSStandard(VS_STANDARD_INPUT input)
{
	VS_STANDARD_OUTPUT output;

	output.positionW = (float3)mul(float4(input.position, 1.0f), gmtxGameObject);
	output.normalW = mul(input.normal, (float3x3)gmtxGameObject);
	output.tangentW = (float3)mul(float4(input.tangent, 1.0f), gmtxGameObject);
	output.bitangentW = (float3)mul(float4(input.bitangent, 1.0f), gmtxGameObject);
	output.position = mul(mul(float4(output.positionW, 1.0f), gmtxView), gmtxProjection);
	output.uv = input.uv;

	return(output);
}

float4 PSStandard(VS_STANDARD_OUTPUT input) : SV_TARGET
{
	float4 cAlbedoColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
	if (gnTexturesMask & MATERIAL_ALBEDO_MAP) cAlbedoColor = gtxtAlbedoTexture.Sample(gssWrap, input.uv);
	float4 cSpecularColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
	if (gnTexturesMask & MATERIAL_SPECULAR_MAP) cSpecularColor = gtxtSpecularTexture.Sample(gssWrap, input.uv);
	float4 cNormalColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
	if (gnTexturesMask & MATERIAL_NORMAL_MAP) cNormalColor = gtxtNormalTexture.Sample(gssWrap, input.uv);
	float4 cMetallicColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
	if (gnTexturesMask & MATERIAL_METALLIC_MAP) cMetallicColor = gtxtMetallicTexture.Sample(gssWrap, input.uv);
	float4 cEmissionColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
	if (gnTexturesMask & MATERIAL_EMISSION_MAP) cEmissionColor = gtxtEmissionTexture.Sample(gssWrap, input.uv);

	float4 cIllumination = float4(1.0f, 1.0f, 1.0f, 1.0f);
	float4 cColor = cAlbedoColor + cSpecularColor + cEmissionColor;
	if (gnTexturesMask & MATERIAL_NORMAL_MAP)
	{
		float3 normalW = input.normalW;
		float3x3 TBN = float3x3(normalize(input.tangentW), normalize(input.bitangentW), normalize(input.normalW));
		float3 vNormal = normalize(cNormalColor.rgb * 2.0f - 1.0f); //[0, 1] ¡æ [-1, 1]
		normalW = normalize(mul(vNormal, TBN));
		cIllumination = Lighting(input.positionW, normalW);
		return(lerp(cColor, cIllumination, 0.5f));
	}
	else
	{
		return(cColor);
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
struct VS_SKYBOX_CUBEMAP_INPUT
{
	float3 position : POSITION;
};

struct VS_SKYBOX_CUBEMAP_OUTPUT
{
	float3	positionL : POSITION;
	float4	position : SV_POSITION;
};

VS_SKYBOX_CUBEMAP_OUTPUT VSSkyBox(VS_SKYBOX_CUBEMAP_INPUT input)
{
	VS_SKYBOX_CUBEMAP_OUTPUT output;

	output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxGameObject), gmtxView), gmtxProjection);
	output.positionL = input.position;

	return(output);
}

TextureCube gtxtSkyCubeTexture : register(t13);
SamplerState gssClamp : register(s1);

float4 PSSkyBox(VS_SKYBOX_CUBEMAP_OUTPUT input) : SV_TARGET
{
	float4 cColor = gtxtSkyCubeTexture.Sample(gssClamp, input.positionL);

	return(cColor);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
Texture2D gtxtTerrainTextureArray[3] : register(t14);

struct VS_TERRAIN_INPUT
{
	float3 position : POSITION;
	float4 color : COLOR;
	float3 normal : NORMAL;
	float2 uv0 : TEXTURE0;
	float2 uv1 : TEXTURE1;
	uint   ntex : TEXTURENUMBER;
};

struct VS_TERRAIN_OUTPUT
{
	float4 position : SV_POSITION;
	float3 positionW : POSITION;
	float4 color : COLOR;
	float3 normalW : NORMAL;
	float2 uv0 : TEXTURE0;
	float2 uv1 : TEXTURE1;
	uint   ntex : TEXTURENUMBER;
};

VS_TERRAIN_OUTPUT VSTerrain(VS_TERRAIN_INPUT input)
{
	VS_TERRAIN_OUTPUT output;

	output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxGameObject), gmtxView), gmtxProjection);
	output.positionW = (float3)mul(float4(input.position, 1.0f), gmtxGameObject);
	output.color = input.color;
	output.normalW = mul(input.normal, (float3x3)gmtxGameObject);
	output.uv0 = input.uv0;
	output.uv1 = input.uv1;
	output.ntex = input.ntex;

	return(output);
}

[maxvertexcount(8)]
void GSTerrain(triangle VS_TERRAIN_OUTPUT input[3], inout TriangleStream<VS_TERRAIN_OUTPUT> outStream)
{
	VS_TERRAIN_OUTPUT v[6];

	v[0].position = input[0].position;
	v[0].positionW = input[0].positionW;
	v[0].color = input[0].color;
	v[0].normalW = input[0].normalW;
	v[0].uv0 = input[0].uv0;
	v[0].uv1 = input[0].uv1;
	v[0].ntex = input[0].ntex;

	v[1].position = input[1].position;
	v[1].positionW = input[1].positionW;
	v[1].color = input[1].color;
	v[1].normalW = input[1].normalW;
	v[1].uv0 = input[1].uv0;
	v[1].uv1 = input[1].uv1;
	v[1].ntex = input[1].ntex;

	v[2].position = input[2].position;
	v[2].positionW = input[2].positionW;
	v[2].color = input[2].color;
	v[2].normalW = input[2].normalW;
	v[2].uv0 = input[2].uv0;
	v[2].uv1 = input[2].uv1;
	v[2].ntex = input[2].ntex;

	v[3].position = (input[0].position + input[1].position) * 0.5f;
	v[3].positionW = (input[0].positionW + input[1].positionW) * 0.5f;
	v[3].color = (input[0].color + input[1].color) * 0.5f;
	v[3].normalW = (input[0].normalW + input[1].normalW) * 0.5f;
	v[3].uv0 = (input[0].uv0 + input[1].uv0) * 0.5f;
	v[3].uv1 = (input[0].uv1 + input[1].uv1) * 0.5f;
	v[3].ntex = input[0].ntex;

	v[4].position = (input[2].position + input[1].position) * 0.5f;
	v[4].positionW = (input[2].positionW + input[1].positionW) * 0.5f;
	v[4].color = (input[2].color + input[1].color) * 0.5f;
	v[4].normalW = (input[2].normalW + input[1].normalW) * 0.5f;
	v[4].uv0 = (input[2].uv0 + input[1].uv0) * 0.5f;
	v[4].uv1 = (input[2].uv1 + input[1].uv1) * 0.5f;
	v[4].ntex = input[2].ntex;

	v[5].position = (input[0].position + input[2].position) * 0.5f;
	v[5].positionW = (input[0].positionW + input[2].positionW) * 0.5f;
	v[5].color = (input[0].color + input[2].color) * 0.5f;
	v[5].normalW = (input[0].normalW + input[2].normalW) * 0.5f;
	v[5].uv0 = (input[0].uv0 + input[2].uv0) * 0.5f;
	v[5].uv1 = (input[0].uv1 + input[2].uv1) * 0.5f;
	v[5].ntex = input[0].ntex;

	outStream.Append(v[0]);
	outStream.Append(v[3]);
	outStream.Append(v[5]);
	outStream.Append(v[4]);
	outStream.Append(v[2]);
	outStream.RestartStrip();
	outStream.Append(v[3]);
	outStream.Append(v[1]);
	outStream.Append(v[4]);
}

float4 PSTerrain(VS_TERRAIN_OUTPUT input) : SV_TARGET
{
	float4 cBaseTexColor = gtxtTerrainTextureArray[0].Sample(gssWrap, input.uv0);
	float4 cDetailTexColor = gtxtTerrainTextureArray[NonUniformResourceIndex(input.ntex)].Sample(gssWrap, input.uv1);

	float3 normalW = input.normalW;
	float4 cIllumination = Lighting(input.positionW, input.normalW);

	float4 cColor = lerp(input.color, cIllumination, 0.5f) * saturate((cBaseTexColor * 1.0f) + (cDetailTexColor * 0.5f));
	//float4 cColor = input.color * saturate((cBaseTexColor * 1.0f) + (cDetailTexColor * 0.5f));

	return(cColor);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

Texture2D gtxtArrayTextures[5] : register(t1);

struct VS_BILLBOARD_IN
{
	float3 posW : POSITION;
	float2 sizeW : SIZE;
	uint   ntexture : TEXTURE;
};

struct VS_BILLBOARD_OUT
{
	float3 centerW : POSITION;
	float2 sizeW : SIZE;
	uint   ntexture : TEXTURE;
};

VS_BILLBOARD_OUT VSBillboard(VS_BILLBOARD_IN input)
{
	VS_BILLBOARD_OUT output;

	output.centerW = input.posW;
	output.sizeW = input.sizeW;
	output.ntexture = input.ntexture;

	return(output);
}

struct GS_BILLBOARD_OUT
{
	float4 posH : SV_POSITION;
	float3 posW : POSITION;
	float3 normalW : NORMAL;
	float2 uv : TEXCOORD;
	uint ntexture : TEXTURE;
};

struct ROTATIONINFO
{
	matrix xmf4x4Rotate;
};

StructuredBuffer<ROTATIONINFO> gRotationInfo : register(t0);

matrix CalculateWorld(float3 center, uint primID)
{
	float3 vUp = float3(0.0f, 1.0f, 0.0f);
	float3 vLook = gvCameraPosition.xyz - center;
	vLook = normalize(vLook);
	vLook.y = 0.0f;
	float3 vRight = normalize(cross(vUp, vLook));

	matrix mtxWorld;
	mtxWorld._11_12_13_14 = float4(vRight, 0.0f);
	mtxWorld._21_22_23_24 = float4(vUp, 0.0f);
	mtxWorld._31_32_33_34 = float4(vLook, 0.0f);
	mtxWorld._41_42_43_44 = float4(center, 1.0f);

	mtxWorld = mul(gRotationInfo[primID % 10].xmf4x4Rotate, mtxWorld);

	return(mtxWorld);
}

[maxvertexcount(4)]
void GSRotateBillboard(point VS_BILLBOARD_OUT input[1], uint primID : SV_PrimitiveID,
	inout TriangleStream<GS_BILLBOARD_OUT> outStream)
{
	float3 vUp = float3(0.0f, 1.0f, 0.0f);
	float3 vLook = gvCameraPosition.xyz - input[0].centerW;
	vLook = normalize(vLook);
	vLook.y = 0.0f;
	float3 vRight = float3(1.0f, 0.0f, 0.0f);
	float fHalfW = input[0].sizeW.x * 0.5f;
	float fHalfH = input[0].sizeW.y;

	float4 fVertices[4];
	fVertices[0] = float4(+fHalfW * vRight, 1.0f);
	fVertices[1] = float4(+fHalfW * vRight + fHalfH * vUp, 1.0f);
	fVertices[2] = float4(-fHalfW * vRight, 1.0f);
	fVertices[3] = float4(-fHalfW * vRight + fHalfH * vUp, 1.0f);

	float2 fUVs[4];
	fUVs[0] = float2(0.0f, 1.0f);
	fUVs[1] = float2(0.0f, 0.0f);
	fUVs[2] = float2(1.0f, 1.0f);
	fUVs[3] = float2(1.0f, 0.0f);

	GS_BILLBOARD_OUT output;

	matrix mtxWorld = CalculateWorld(input[0].centerW, primID);

	for (int i = 0; i < 4; i++)
	{
		//output.posH = mul(mul(fVertices[i], gmtxView), gmtxProjection);
		output.posH = mul(mul(mul(fVertices[i], mtxWorld), gmtxView), gmtxProjection);
		output.posW = input[0].centerW + fVertices[i].xyz;
		output.normalW = vLook;
		output.uv = fUVs[i];
		output.ntexture = input[0].ntexture;

		outStream.Append(output);
	}
}

[maxvertexcount(4)]
void GSBillboard(point VS_BILLBOARD_OUT input[1], uint primID : SV_PrimitiveID,
	inout TriangleStream<GS_BILLBOARD_OUT> outStream)
{
	float3 vUp = float3(0.0f, 1.0f, 0.0f);
	float3 vLook = gvCameraPosition.xyz - input[0].centerW;
	vLook = normalize(vLook);
	vLook.y = 0.0f;
	float3 vRight = normalize(cross(vUp, vLook));

	float fHalfW = input[0].sizeW.x * 0.5f;
	float fHalfH = input[0].sizeW.y;

	float4 fVertices[4];
	fVertices[0] = float4(input[0].centerW + fHalfW * vRight, 1.0f);
	fVertices[1] = float4(input[0].centerW + fHalfW * vRight + fHalfH * vUp, 1.0f);
	fVertices[2] = float4(input[0].centerW - fHalfW * vRight, 1.0f);
	fVertices[3] = float4(input[0].centerW - fHalfW * vRight + fHalfH * vUp, 1.0f);

	float2 fUVs[4];
	fUVs[0] = float2(0.0f, 1.0f);
	fUVs[1] = float2(0.0f, 0.0f);
	fUVs[2] = float2(1.0f, 1.0f);
	fUVs[3] = float2(1.0f, 0.0f);

	GS_BILLBOARD_OUT output;

	for (int i = 0; i < 4; i++)
	{
		//output.posH = mul(mul(fVertices[i], gmtxView), gmtxProjection);
		output.posH = mul(mul(fVertices[i], gmtxView), gmtxProjection);
		output.posW = fVertices[i].xyz; 
		output.normalW = vLook;
		output.uv = fUVs[i];
		output.ntexture = input[0].ntexture;

		outStream.Append(output);
	}
}

float4 PSBillboard(GS_BILLBOARD_OUT input) : SV_TARGET
{
	float4 cColor = gtxtArrayTextures[NonUniformResourceIndex(input.ntexture)].SampleLevel(gssWrap, input.uv, 0);

	float3 normalW = input.normalW;
	float4 cIllumination = Lighting(input.posW, normalW);
		
	return(lerp(cColor, cIllumination, 0.5f));
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

struct VS_TEXTURED_INPUT
{
	float3 position : POSITION;
	float2 uv : TEXCOORD;
};

struct VS_TEXTURED_OUTPUT
{
	float4 position : SV_POSITION;
	float2 uv : TEXCOORD;
};

VS_TEXTURED_OUTPUT VSTextured(VS_TEXTURED_INPUT input)
{
	VS_TEXTURED_OUTPUT output;

	output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxGameObject), gmtxView), gmtxProjection);
	output.uv = input.uv;

	return(output);
}

float4 PSTextured(VS_TEXTURED_OUTPUT input, uint primitiveID : SV_PrimitiveID) : SV_TARGET
{
	float4 cColor = gtxtArrayTextures[0].SampleLevel(gssWrap, input.uv, 0);

	return(cColor);
}

cbuffer cbTextureSprite : register(b3)
{
	float4	gfTextureSpriteInfo : packoffset(c0);
};

VS_TEXTURED_OUTPUT VSEffect(VS_TEXTURED_INPUT input)
{
	VS_TEXTURED_OUTPUT output;

	output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxGameObject), gmtxView), gmtxProjection);

	float3x3 f3x3Sprite = float3x3(gfTextureSpriteInfo.x, 0.0f, 0.0f, 0.0f, gfTextureSpriteInfo.y, 0.0f, input.uv.x * gfTextureSpriteInfo.x, input.uv.y * gfTextureSpriteInfo.y, 1.0f);
	float3 f3Sprite = float3(gfTextureSpriteInfo.zw, 1.0f);
	output.uv = (float2)mul(f3Sprite, f3x3Sprite);

	return(output);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
struct VS_UI_INPUT
{
	float2 center : POSITION;
	float2 size : SIZE;
};

struct VS_UI_OUTPUT
{
	float2 center : POSITION;
	float2 size : SIZE;
};

VS_UI_OUTPUT VS_UI(VS_UI_INPUT input)
{
	VS_UI_OUTPUT output;

	output.center = input.center;
	output.size = input.size;

	return(output);
}

struct GS_OUT
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD;
};

[maxvertexcount(4)]
void GS_UI(point VS_UI_OUTPUT input[1], uint primID : SV_PrimitiveID, inout TriangleStream<GS_OUT> outStream)
{
	float2 vUp = float2(0.0f, 1.0f);
	float2 vRight = float2(1.0f, 0.0f);
	float fHalfW = input[0].size.x;
	float fHalfH = input[0].size.y;

	float4 fVertices[4];
	fVertices[0] = float4(input[0].center + fHalfW * vRight, 0.0f, 1.0f);
	fVertices[1] = float4(input[0].center + fHalfW * vRight + fHalfH * vUp, 0.0f, 1.0f);
	fVertices[2] = float4(input[0].center - fHalfW * vRight, 0.0f, 1.0f);
	fVertices[3] = float4(input[0].center - fHalfW * vRight + fHalfH * vUp, 0.0f, 1.0f);

	float2 fUVs[4];
	fUVs[0] = float2(0.0f, 1.0f);
	fUVs[1] = float2(0.0f, 0.0f);
	fUVs[2] = float2(1.0f, 1.0f);
	fUVs[3] = float2(1.0f, 0.0f);

	GS_OUT output;

	for (int i = 0; i < 4; i++)
	{
		output.pos = fVertices[i];
		output.uv = fUVs[i];

		outStream.Append(output);
	}
}

float4 PS_UI(GS_OUT input) : SV_TARGET
{
	float4 cColor = gtxtArrayTextures[0].Sample(gssWrap, input.uv);

	return(cColor);
}


///////////////////////////////////////////////////////////////////////////////////////////