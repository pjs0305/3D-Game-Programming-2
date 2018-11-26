//#define _WITH_CONSTANT_BUFFER_SYNTAX

#ifdef _WITH_CONSTANT_BUFFER_SYNTAX
struct CB_PLAYER_INFO
{
	matrix		mtxWorld;
};

struct CB_GAMEOBJECT_INFO
{
	matrix		mtxWorld;
};

struct CB_CAMERA_INFO
{
	matrix		mtxView;
	matrix		mtxProjection;
	float3		vCameraPosition;
};

ConstantBuffer<CB_PLAYER_INFO> gcbPlayerObjectInfo : register(b0);
ConstantBuffer<CB_CAMERA_INFO> gcbCameraInfo : register(b1);
ConstantBuffer<CB_GAMEOBJECT_INFO> gcbGameObjectInfo : register(b2);
#else
cbuffer cbPlayerInfo : register(b0)
{
	matrix		gmtxPlayerWorld : packoffset(c0);
};

cbuffer cbCameraInfo : register(b1)
{
	matrix		gmtxView : packoffset(c0);
	matrix		gmtxProjection : packoffset(c4);
	float3		gvCameraPosition : packoffset(c8);
};

cbuffer cbGameObjectInfo : register(b2)
{
	matrix		gmtxWorld : packoffset(c0);
};
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

struct VS_WIRE_INPUT
{
	float3 position : POSITION;
};

struct VS_WIRE_OUTPUT
{
	float4 position : SV_POSITION;
};

VS_WIRE_OUTPUT VSWire(VS_WIRE_INPUT input)
{
	VS_WIRE_OUTPUT output;

	output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxWorld), gmtxView), gmtxProjection);

	return(output);
}

float4 PSWire(VS_WIRE_OUTPUT input) : SV_TARGET
{
	return(float4(1.0f, 0.0f,0.0f,0.0f));
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

struct VS_DIFFUSED_INPUT
{
	float3 position : POSITION;
	float4 color : COLOR;
};

struct VS_DIFFUSED_OUTPUT
{
	float4 position : SV_POSITION;
	float4 color : COLOR;
};

VS_DIFFUSED_OUTPUT VSDiffused(VS_DIFFUSED_INPUT input)
{
	VS_DIFFUSED_OUTPUT output;

#ifdef _WITH_CONSTANT_BUFFER_SYNTAX
	output.position = mul(mul(mul(float4(input.position, 1.0f), gcbGameObjectInfo.mtxWorld), gcbCameraInfo.mtxView), gcbCameraInfo.mtxProjection);
#else
	output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxWorld), gmtxView), gmtxProjection);
#endif
	output.color = input.color;

	return(output);
}

float4 PSDiffused(VS_DIFFUSED_OUTPUT input) : SV_TARGET
{
	return(input.color);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
VS_DIFFUSED_OUTPUT VSPlayer(VS_DIFFUSED_INPUT input)
{
	VS_DIFFUSED_OUTPUT output;

#ifdef _WITH_CONSTANT_BUFFER_SYNTAX
	output.position = mul(mul(mul(float4(input.position, 1.0f), gcbPlayerObjectInfo.mtxWorld), gcbCameraInfo.mtxView), gcbCameraInfo.mtxProjection);
#else
	output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxPlayerWorld), gmtxView), gmtxProjection);
#endif
	output.color = input.color;

	return(output);
}

float4 PSPlayer(VS_DIFFUSED_OUTPUT input) : SV_TARGET
{
	return(input.color);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
Texture2D gtxtTexture : register(t4);

SamplerState gWrapSamplerState : register(s0);
SamplerState gClampSamplerState : register(s1);

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

#ifdef _WITH_CONSTANT_BUFFER_SYNTAX
	output.position = mul(mul(mul(float4(input.position, 1.0f), gcbGameObjectInfo.mtxWorld), gcbCameraInfo.mtxView), gcbCameraInfo.mtxProjection);
#else
	output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxWorld), gmtxView), gmtxProjection);
#endif
	output.uv = input.uv;

	return(output);
}

float4 PSTextured(VS_TEXTURED_OUTPUT input, uint primitiveID : SV_PrimitiveID) : SV_TARGET
{
	float4 cColor = gtxtTexture.Sample(gWrapSamplerState, input.uv);

	return(cColor);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
float4 PSSkyBox(VS_TEXTURED_OUTPUT input) : SV_TARGET
{
	float4 cColor = gtxtTexture.Sample(gClampSamplerState, input.uv);

	return(cColor);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
Texture2D gtxtTerrainTextureArray[3] : register(t1);

struct VS_TERRAIN_INPUT
{
	float3 position : POSITION;
	float4 color : COLOR;
	float2 uv0 : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	uint   ntex : TEXTURENUM;
};

struct VS_TERRAIN_OUTPUT
{
	float4 position : SV_POSITION;
	float4 color : COLOR;
	float2 uv0 : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	uint   ntex : TEXTURENUM;
};

VS_TERRAIN_OUTPUT VSTerrain(VS_TERRAIN_INPUT input)
{
	VS_TERRAIN_OUTPUT output;

#ifdef _WITH_CONSTANT_BUFFER_SYNTAX
	output.position = mul(mul(mul(float4(input.position, 1.0f), gcbGameObjectInfo.mtxWorld), gcbCameraInfo.mtxView), gcbCameraInfo.mtxProjection);
#else
	output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxWorld), gmtxView), gmtxProjection);
#endif
	output.color = input.color;
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
	v[0].color = input[0].color;
	v[0].uv0 = input[0].uv0;
	v[0].uv1 = input[0].uv1;
	v[0].ntex = input[0].ntex;

	v[1].position = input[1].position;
	v[1].color = input[1].color;
	v[1].uv0 = input[1].uv0;
	v[1].uv1 = input[1].uv1;
	v[1].ntex = input[1].ntex;	

	v[2].position = input[2].position;
	v[2].color = input[2].color;
	v[2].uv0 = input[2].uv0;
	v[2].uv1 = input[2].uv1;
	v[2].ntex = input[2].ntex;

	v[3].position = (input[0].position + input[1].position) * 0.5f;
	v[3].color = (input[0].color + input[1].color) * 0.5f;
	v[3].uv0 = (input[0].uv0 + input[1].uv0) * 0.5f;
	v[3].uv1 = (input[0].uv1 + input[1].uv1) * 0.5f;
	v[3].ntex = input[0].ntex;

	v[4].position = (input[2].position + input[1].position) * 0.5f;
	v[4].color = (input[2].color + input[1].color) * 0.5f;
	v[4].uv0 = (input[2].uv0 + input[1].uv0) * 0.5f;
	v[4].uv1 = (input[2].uv1 + input[1].uv1) * 0.5f;
	v[4].ntex = input[2].ntex;

	v[5].position = (input[0].position + input[2].position) * 0.5f;
	v[5].color = (input[0].color + input[2].color) * 0.5f;
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
	float4 cBaseTexColor = gtxtTerrainTextureArray[0].Sample(gWrapSamplerState, input.uv0);
	float4 cDetailTexColor = gtxtTerrainTextureArray[NonUniformResourceIndex(input.ntex)].Sample(gWrapSamplerState, input.uv1);
	float4 cColor = input.color * saturate((cBaseTexColor * 1.0f) + (cDetailTexColor * 0.5f));

	return(cColor);
}

[maxvertexcount(8)]
void GSTerrainWire(triangle VS_WIRE_OUTPUT input[3], inout TriangleStream<VS_WIRE_OUTPUT> outStream)
{
	VS_WIRE_OUTPUT v[6];

	v[0].position = input[0].position;
	v[1].position = input[1].position;
	v[2].position = input[2].position;
	v[3].position = (input[0].position + input[1].position) * 0.5f;
	v[4].position = (input[2].position + input[1].position) * 0.5f;
	v[5].position = (input[0].position + input[2].position) * 0.5f;

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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

Texture2D gtxtArrayTextures[5] : register(t5);

struct VS_BILLBOARD_IN
{
	float3 posW : POSITION;
	float2 sizeW : SIZE;
	uint   ntexture : TEXTURE;
};

struct VS_BILLBOARD_OUT
{
	float4 position : SV_POSITION;
	uint   ntexture : TEXTURE;
};

VS_BILLBOARD_OUT VSBillboard(VS_BILLBOARD_IN input)
{
	VS_BILLBOARD_OUT output;

	output.position = mul(mul(mul(float4(input.posW, 1.0f), gmtxWorld), gmtxView), gmtxProjection);
	output.ntexture = input.ntexture;

	return(output);
}

float4 PSBillboard(VS_BILLBOARD_OUT input) : SV_TARGET
{
	float4 cColor = gtxtArrayTextures[NonUniformResourceIndex(input.ntexture)].SampleLevel(gWrapSamplerState, float2(0.5f,0.5f), 0);
	if (cColor.a <= 0.3f) discard;

	return(cColor);
}

////////////////////////////////////

struct VS_GEOMETRY_BILLBOARD_OUT
{
	float3 centerW : POSITION;
	float2 sizeW : SIZE;
	uint   ntexture : TEXTURE;
};

VS_GEOMETRY_BILLBOARD_OUT VSGeometryBillboard(VS_BILLBOARD_IN input)
{
	VS_GEOMETRY_BILLBOARD_OUT output;

	output.centerW = input.posW;
	output.sizeW = input.sizeW;
	output.ntexture = input.ntexture;

	return(output);
}

struct GS_BILLBOARD_OUT
{
	float4 posH : SV_POSITION;
	//float3 posW : POSITION;
	//float2 normalW : NORMAL;
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

	mtxWorld = mul(gRotationInfo[primID % 5].xmf4x4Rotate, mtxWorld);

	return(mtxWorld);
}

[maxvertexcount(4)]
void GSRotateBillboard(point VS_GEOMETRY_BILLBOARD_OUT input[1], uint primID : SV_PrimitiveID,
	inout TriangleStream<GS_BILLBOARD_OUT> outStream)
{
	float3 vUp = float3(0.0f, 1.0f, 0.0f);
	float3 vLook = float3(0.0f, 0.0f, 1.0f);
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
		//output.posW = fVertices[i].xyz; 
		//output.normalW = vLook;
		output.uv = fUVs[i];
		output.ntexture = input[0].ntexture;

		outStream.Append(output);
	}
}

[maxvertexcount(4)]
void GSBillboard(point VS_GEOMETRY_BILLBOARD_OUT input[1], uint primID : SV_PrimitiveID,
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
		//output.posW = fVertices[i].xyz; 
		//output.normalW = vLook;
		output.uv = fUVs[i];
		output.ntexture = input[0].ntexture;

		outStream.Append(output);
	}
}
float4 PSGeometryBillboard(GS_BILLBOARD_OUT input) : SV_TARGET
{
	float4 cColor = gtxtArrayTextures[NonUniformResourceIndex(input.ntexture)].SampleLevel(gWrapSamplerState, input.uv, 0);
	if (cColor.a <= 0.3f) discard;

	return(cColor);
}

struct VS_BILLBOARD_WIRE_IN
{
	float3 posW : POSITION;
	float2 sizeW : SIZE;
};

////////////////////////////////////

struct VS_GEOMETRY_BILLBOARD_WIRE_OUT
{
	float3 centerW : POSITION;
	float2 sizeW : SIZE;
};

VS_GEOMETRY_BILLBOARD_WIRE_OUT VSGeometryBillboardWire(VS_BILLBOARD_WIRE_IN input)
{
	VS_GEOMETRY_BILLBOARD_WIRE_OUT output;

	output.centerW = input.posW;
	output.sizeW = input.sizeW;

	return(output);
}

struct GS_BILLBOARD_WIRE_OUT
{
	float4 posH : SV_POSITION;
};

[maxvertexcount(4)]
void GSRotateBillboardWire(point VS_GEOMETRY_BILLBOARD_WIRE_OUT input[1], uint primID : SV_PrimitiveID,
	inout TriangleStream<GS_BILLBOARD_WIRE_OUT> outStream)
{
	float3 vUp = float3(0.0f, 1.0f, 0.0f);
	float3 vLook = float3(0.0f, 0.0f, 1.0f);
	float3 vRight = float3(1.0f, 0.0f, 0.0f);
	float fHalfW = input[0].sizeW.x * 0.5f;
	float fHalfH = input[0].sizeW.y;

	float4 fVertices[4];
	fVertices[0] = float4(+fHalfW * vRight, 1.0f);
	fVertices[1] = float4(+fHalfW * vRight + fHalfH * vUp, 1.0f);
	fVertices[2] = float4(-fHalfW * vRight, 1.0f);
	fVertices[3] = float4(-fHalfW * vRight + fHalfH * vUp, 1.0f);

	GS_BILLBOARD_WIRE_OUT output;

	matrix mtxWorld = CalculateWorld(input[0].centerW, primID);

	for (int i = 0; i < 4; i++)
	{
		output.posH = mul(mul(mul(fVertices[i], mtxWorld), gmtxView), gmtxProjection);

		outStream.Append(output);
	}
}

[maxvertexcount(4)]
void GSBillboardWire(point VS_GEOMETRY_BILLBOARD_WIRE_OUT input[1], uint primID : SV_PrimitiveID,
	inout TriangleStream<GS_BILLBOARD_WIRE_OUT> outStream)
{
	float3 vUp = float3(0.0f, 1.0f, 0.0f);
	float3 vLook = gvCameraPosition.xyz - input[0].centerW;
	vLook = normalize(vLook);
	float3 vRight = cross(vUp, vLook);
	float fHalfW = input[0].sizeW.x * 0.5f;
	float fHalfH = input[0].sizeW.y;

	float4 fVertices[4];
	fVertices[0] = float4(input[0].centerW + fHalfW * vRight, 1.0f);
	fVertices[1] = float4(input[0].centerW + fHalfW * vRight + fHalfH * vUp, 1.0f);
	fVertices[2] = float4(input[0].centerW - fHalfW * vRight, 1.0f);
	fVertices[3] = float4(input[0].centerW - fHalfW * vRight + fHalfH * vUp, 1.0f);

	GS_BILLBOARD_WIRE_OUT output;
	for (int i = 0; i < 4; i++)
	{
		output.posH = mul(mul(fVertices[i], gmtxView), gmtxProjection);

		outStream.Append(output);
	}
}
float4 PSGeometryBillboardWire(GS_BILLBOARD_WIRE_OUT input) : SV_TARGET
{
	return(float4(0.0f, 1.0f, 0.0f, 1.0f));
}
