//-----------------------------------------------------------------------------
// File: Shader.h
//-----------------------------------------------------------------------------

#pragma once

#include "Object.h"
#include "Camera.h"

class CShader
{
public:
	CShader();
	virtual ~CShader();

private:
	int								m_nReferences = 0;

public:
	void AddRef() { m_nReferences++; }
	void Release() { if (--m_nReferences <= 0) delete this; }

	virtual D3D12_INPUT_LAYOUT_DESC CreateInputLayout();
	virtual D3D12_RASTERIZER_DESC CreateRasterizerState();
	virtual D3D12_BLEND_DESC CreateBlendState();
	virtual D3D12_DEPTH_STENCIL_DESC CreateDepthStencilState();

	virtual D3D12_SHADER_BYTECODE CreateVertexShader(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_SHADER_BYTECODE CreatePixelShader(ID3DBlob **ppd3dShaderBlob);
	D3D12_SHADER_BYTECODE CompileShaderFromFile(WCHAR *pszFileName, LPCSTR pszShaderName, LPCSTR pszShaderProfile, ID3DBlob **ppd3dShaderBlob);

	virtual void CreateShader(ID3D12Device *pd3dDevice, ID3D12RootSignature *pd3dGraphicsRootSignature);

	void CreateCbvSrvDescriptorHeaps(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, int nConstantBufferViews, int nShaderResourceViews);
	void CreateConstantBufferViews(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, int nConstantBufferViews, ID3D12Resource *pd3dConstantBuffers, UINT nStride);
	void CreateShaderResourceViews(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, CTexture *pTexture, UINT nRootParameterStartIndex, bool bAutoIncrement);

	virtual void CreateShaderVariables(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList);
	virtual void UpdateShaderVariables(ID3D12GraphicsCommandList *pd3dCommandList);
	virtual void ReleaseShaderVariables();

	virtual void UpdateShaderVariable(ID3D12GraphicsCommandList *pd3dCommandList, XMFLOAT4X4 *pxmf4x4World);

	virtual void BuildObjects(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, void *pContext=NULL) { }
	virtual void AnimateObjects(float fTimeElapsed, CCamera* pCamera) { }
	virtual void ReleaseObjects() { }

	virtual void ReleaseUploadBuffers();

	virtual void OnPrepareRender(ID3D12GraphicsCommandList *pd3dCommandList, UINT PipelineStatesIndex = 0);
	virtual void Render(ID3D12GraphicsCommandList *pd3dCommandList, UINT PipelineStatesIndex = 0);

	D3D12_CPU_DESCRIPTOR_HANDLE GetCPUDescriptorHandleForHeapStart() { return(m_pd3dCbvSrvDescriptorHeap->GetCPUDescriptorHandleForHeapStart()); }
	D3D12_GPU_DESCRIPTOR_HANDLE GetGPUDescriptorHandleForHeapStart() { return(m_pd3dCbvSrvDescriptorHeap->GetGPUDescriptorHandleForHeapStart()); }

	D3D12_CPU_DESCRIPTOR_HANDLE GetCPUCbvDescriptorStartHandle() { return(m_d3dCbvCPUDescriptorStartHandle); }
	D3D12_GPU_DESCRIPTOR_HANDLE GetGPUCbvDescriptorStartHandle() { return(m_d3dCbvGPUDescriptorStartHandle); }
	D3D12_CPU_DESCRIPTOR_HANDLE GetCPUSrvDescriptorStartHandle() { return(m_d3dSrvCPUDescriptorStartHandle); }
	D3D12_GPU_DESCRIPTOR_HANDLE GetGPUSrvDescriptorStartHandle() { return(m_d3dSrvGPUDescriptorStartHandle); }

protected:
	ID3D12PipelineState				**m_ppd3dPipelineStates = NULL;
	int								m_nPipelineStates = 0;

	ID3D12DescriptorHeap			*m_pd3dCbvSrvDescriptorHeap = NULL;

	D3D12_CPU_DESCRIPTOR_HANDLE		m_d3dCbvCPUDescriptorStartHandle;
	D3D12_GPU_DESCRIPTOR_HANDLE		m_d3dCbvGPUDescriptorStartHandle;
	D3D12_CPU_DESCRIPTOR_HANDLE		m_d3dSrvCPUDescriptorStartHandle;
	D3D12_GPU_DESCRIPTOR_HANDLE		m_d3dSrvGPUDescriptorStartHandle;

public:
	virtual D3D12_INPUT_LAYOUT_DESC CreateInputLayoutWire();
	virtual D3D12_SHADER_BYTECODE CreateVertexShaderWire(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_RASTERIZER_DESC CreateRasterizerStateWire();
	virtual D3D12_SHADER_BYTECODE CreatePixelShaderWire(ID3DBlob **ppd3dShaderBlob);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
class CPlayerShader : public CShader
{
public:
	CPlayerShader();
	virtual ~CPlayerShader();

	virtual D3D12_INPUT_LAYOUT_DESC CreateInputLayout();
	virtual D3D12_SHADER_BYTECODE CreateVertexShader(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_SHADER_BYTECODE CreatePixelShader(ID3DBlob **ppd3dShaderBlob);

	virtual void CreateShader(ID3D12Device *pd3dDevice, ID3D12RootSignature *pd3dGraphicsRootSignature);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
class CTexturedShader : public CShader
{
public:
	CTexturedShader();
	virtual ~CTexturedShader();

	virtual D3D12_INPUT_LAYOUT_DESC CreateInputLayout();

	virtual void CreateShader(ID3D12Device *pd3dDevice, ID3D12RootSignature *pd3dGraphicsRootSignature);

	virtual D3D12_SHADER_BYTECODE CreateVertexShader(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_SHADER_BYTECODE CreatePixelShader(ID3DBlob **ppd3dShaderBlob);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

class CObjectsShader : public CTexturedShader
{
public:
    CObjectsShader();
    virtual ~CObjectsShader();

	virtual void BuildObjects(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, void *pContext=NULL);
	virtual void AnimateObjects(float fTimeElapsed, CCamera* pCamera);
	virtual void ReleaseObjects();

	virtual void CreateShaderVariables(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList);
	virtual void UpdateShaderVariables(ID3D12GraphicsCommandList *pd3dCommandList);
	virtual void ReleaseShaderVariables();

	virtual D3D12_SHADER_BYTECODE CreatePixelShader(ID3DBlob **ppd3dShaderBlob);

	virtual void ReleaseUploadBuffers();

	virtual void Render(ID3D12GraphicsCommandList *pd3dCommandList, UINT PipelineStatesIndex);

protected:
	CGameObject						**m_ppObjects = NULL;
	int								m_nObjects = 0;

	CMaterial						*m_pMaterial = NULL;

	ID3D12Resource					*m_pd3dcbGameObjects = NULL;
	CB_GAMEOBJECT_INFO				*m_pcbMappedGameObjects = NULL;
};

class CBillboardObjectsShader : public CObjectsShader
{
public:
	CBillboardObjectsShader();
	virtual ~CBillboardObjectsShader();

	virtual D3D12_RASTERIZER_DESC CreateRasterizerState();
	virtual void BuildObjects(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList,
		CMesh* pMesh, wchar_t *pszTextFileName, UINT nType, void *pContext = NULL) {}
	virtual void ReleaseObjects();
	virtual void AnimateObjects(float fTimeElapsed, CCamera* pCamera);
	virtual void Render(ID3D12GraphicsCommandList *pd3dCommandList, UINT PipelineStatesIndex);

	virtual void ReleaseUploadBuffers();
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

class CInstancingBillboardObjectsShader : public CBillboardObjectsShader
{
public:
	CInstancingBillboardObjectsShader() {};
	virtual ~CInstancingBillboardObjectsShader() {};

	virtual D3D12_SHADER_BYTECODE CreateVertexShader(ID3DBlob **ppd3dShaderBlob);

	virtual void CreateShaderVariables(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList);
	virtual void UpdateShaderVariables(ID3D12GraphicsCommandList *pd3dCommandList);

	void CreateSrvDescriptorHeaps(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, int nShaderResourceViews);
	
	virtual void BuildObjects(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, CMesh* pMesh, wchar_t *pszTextFileName, UINT nType, void *pContext = NULL) {}

	virtual void OnPrepareRender(ID3D12GraphicsCommandList *pd3dCommandList, UINT PipelineStatesIndex = 0);
	virtual void Render(ID3D12GraphicsCommandList *pd3dCommandList, UINT PipelineStatesIndex = 0);

protected:
	ID3D12Resource					*m_pd3dcbGameObjects = NULL;
	CB_BILLBOARDGAMEOBJECT_INFO		*m_pcbMappedGameObjects = NULL;

	ID3D12DescriptorHeap			*m_pd3dSrvDescriptorHeap = NULL;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

class CVerticesObjectsShader : public CTexturedShader
{
public:
	CVerticesObjectsShader();
	virtual ~CVerticesObjectsShader();

	virtual void CreateShader(ID3D12Device *pd3dDevice, ID3D12RootSignature *pd3dGraphicsRootSignature);
	virtual D3D12_SHADER_BYTECODE CreateVertexShader(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_SHADER_BYTECODE CreatePixelShader(ID3DBlob **ppd3dShaderBlob);

	virtual D3D12_SHADER_BYTECODE CreateGeometryVertexShader(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_SHADER_BYTECODE CreateGeometryShader(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_SHADER_BYTECODE CreateGeometryPixelShader(ID3DBlob **ppd3dShaderBlob);

	virtual D3D12_SHADER_BYTECODE CreateGeometryVertexShaderWire(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_SHADER_BYTECODE CreateGeometryShaderWire(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_SHADER_BYTECODE CreateGeometryPixelShaderWire(ID3DBlob **ppd3dShaderBlob);

	virtual D3D12_INPUT_LAYOUT_DESC CreateInputLayout();
	virtual D3D12_INPUT_LAYOUT_DESC CreateGeometryInputLayoutWire();
	virtual D3D12_RASTERIZER_DESC CreateRasterizerState();
	virtual D3D12_RASTERIZER_DESC CreateRasterizerStateWire();

	virtual void CreateShaderVariables(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList) {}
	virtual void UpdateShaderVariables(ID3D12GraphicsCommandList *pd3dCommandList) {}

	virtual void BuildObjects(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, void *pContext = NULL) {}
	virtual void AnimateObjects(float fTimeElapsed, CCamera* pCamera) {}
	virtual void ReleaseObjects() {};

	void CreateSrvDescriptorHeaps(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, int nShaderResourceViews);

	virtual void ReleaseShaderVariables();
	virtual void ReleaseUploadBuffers();

	virtual void OnPrepareRender(ID3D12GraphicsCommandList *pd3dCommandList, UINT PipelineStatesIndex = 0);
	virtual void Render(ID3D12GraphicsCommandList *pd3dCommandList, UINT PipelineStatesIndex = 0);

protected:
	CMaterial						*m_pMaterial = NULL;

	UINT							m_nVertices;
	CBillboardVertex				*m_pVertices;

	ID3D12Resource					*m_pd3dVertexBuffer = NULL;
	ID3D12Resource					*m_pd3dVertexUploadBuffer = NULL;

	D3D12_VERTEX_BUFFER_VIEW		m_d3dVertexBufferView;

	ID3D12DescriptorHeap			*m_pd3dSrvDescriptorHeap = NULL;
};

////////////////////////////////////////////////////////////////////////////////////////////

struct ROTATIONINFO
{
	XMFLOAT4X4 xmf4x4Rotate;
};

class CFlowerObjectsShader : public CVerticesObjectsShader
{
public:
	CFlowerObjectsShader();
	virtual ~CFlowerObjectsShader();

	virtual D3D12_SHADER_BYTECODE CreateGeometryShader(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_SHADER_BYTECODE CreateGeometryShaderWire(ID3DBlob **ppd3dShaderBlob);

	virtual void CreateShaderVariables(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList);
	virtual void UpdateShaderVariables(ID3D12GraphicsCommandList *pd3dCommandList);

	virtual void BuildObjects(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, void *pContext = NULL);
	virtual void AnimateObjects(float fTimeElapsed, CCamera* pCamera);

protected:
	ID3D12Resource		*m_pd3dsbRotations = NULL;
	ROTATIONINFO		*m_psbMappedRotations = NULL;

#define NUMROTATEMATRIX 10
	ROTATIONINFO		m_Rotation[NUMROTATEMATRIX];
	float				m_fRotationAngle[NUMROTATEMATRIX];
	float				m_fRotationDelta[NUMROTATEMATRIX];
};

class CTreeObjectsShader : public CVerticesObjectsShader
{
public:
	CTreeObjectsShader();
	virtual ~CTreeObjectsShader();

	virtual void BuildObjects(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, void *pContext = NULL);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

class CTerrainShader : public CTexturedShader
{
public:
	CTerrainShader();
	virtual ~CTerrainShader();

	virtual D3D12_INPUT_LAYOUT_DESC CreateInputLayout();
	virtual D3D12_SHADER_BYTECODE CreateVertexShader(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_SHADER_BYTECODE CreateGeometryShader(ID3DBlob **ppd3dShaderBlob);
	virtual D3D12_SHADER_BYTECODE CreatePixelShader(ID3DBlob **ppd3dShaderBlob);

	virtual D3D12_SHADER_BYTECODE CreateGeometryShaderWire(ID3DBlob **ppd3dShaderBlob);

	virtual void CreateShader(ID3D12Device *pd3dDevice, ID3D12RootSignature *pd3dGraphicsRootSignature);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
class CSkyBoxShader : public CTexturedShader
{
public:
	CSkyBoxShader();
	virtual ~CSkyBoxShader();

	virtual D3D12_DEPTH_STENCIL_DESC CreateDepthStencilState();
	virtual D3D12_SHADER_BYTECODE CreatePixelShader(ID3DBlob **ppd3dShaderBlob);

	virtual void CreateShader(ID3D12Device *pd3dDevice, ID3D12RootSignature *pd3dGraphicsRootSignature);
};
