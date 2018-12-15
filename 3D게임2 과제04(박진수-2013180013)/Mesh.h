//------------------------------------------------------- ----------------------
// File: Mesh.h
//-----------------------------------------------------------------------------

#pragma once

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
#define VERTEXT_POSITION				0x01
#define VERTEXT_COLOR					0x02
#define VERTEXT_NORMAL					0x04
#define VERTEXT_TANGENT					0x08
#define VERTEXT_TEXTURE_COORD0			0x10
#define VERTEXT_TEXTURE_COORD1			0x20

#define VERTEXT_TEXTURE					(VERTEXT_POSITION | VERTEXT_TEXTURE_COORD0)
#define VERTEXT_DETAIL					(VERTEXT_POSITION | VERTEXT_TEXTURE_COORD0 | VERTEXT_TEXTURE_COORD1)
#define VERTEXT_NORMAL_TEXTURE			(VERTEXT_POSITION | VERTEXT_NORMAL | VERTEXT_TEXTURE_COORD0)
#define VERTEXT_NORMAL_TANGENT_TEXTURE	(VERTEXT_POSITION | VERTEXT_NORMAL | VERTEXT_TANGENT | VERTEXT_TEXTURE_COORD0)
#define VERTEXT_NORMAL_DETAIL			(VERTEXT_POSITION | VERTEXT_NORMAL | VERTEXT_TEXTURE_COORD0 | VERTEXT_TEXTURE_COORD1)
#define VERTEXT_NORMAL_TANGENT__DETAIL	(VERTEXT_POSITION | VERTEXT_NORMAL | VERTEXT_TANGENT | VERTEXT_TEXTURE_COORD0 | VERTEXT_TEXTURE_COORD1)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
class CMesh
{
public:
	CMesh(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList);
	virtual ~CMesh();

	int								m_nReferences = 0;
private:

public:
	void AddRef() { m_nReferences++; }
	void Release() { if (--m_nReferences <= 0) delete this; }

protected:
	char							m_pstrMeshName[256] = { 0 };

	UINT							m_nType = 0x00;

	D3D12_PRIMITIVE_TOPOLOGY		m_d3dPrimitiveTopology = D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
	UINT							m_nSlot = 0;
	UINT							m_nOffset = 0;

protected:
	int								m_nVertices = 0;

	XMFLOAT3						*m_pxmf3Positions = NULL;

	ID3D12Resource					*m_pd3dPositionBuffer = NULL;
	ID3D12Resource					*m_pd3dPositionUploadBuffer = NULL;
	D3D12_VERTEX_BUFFER_VIEW		m_d3dPositionBufferView;

	int								m_nSubMeshes = 0;
	int								*m_pnSubSetIndices = NULL;
	UINT							**m_ppnSubSetIndices = NULL;

	ID3D12Resource					**m_ppd3dSubSetIndexBuffers = NULL;
	ID3D12Resource					**m_ppd3dSubSetIndexUploadBuffers = NULL;
	D3D12_INDEX_BUFFER_VIEW			*m_pd3dSubSetIndexBufferViews = NULL;

public:
	UINT GetType() { return(m_nType); }

	virtual void ReleaseUploadBuffers();
	virtual void Render(ID3D12GraphicsCommandList *pd3dCommandList, int nSubSet);

public:
	BoundingBox						m_xmAABB;

	XMFLOAT3						m_xmf3AABBCenter = XMFLOAT3(0.0f, 0.0f, 0.0f);
	XMFLOAT3						m_xmf3AABBExtents = XMFLOAT3(0.0f, 0.0f, 0.0f);
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
class CSkyBoxMesh : public CMesh
{
public:
	CSkyBoxMesh(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, float fWidth = 20.0f, float fHeight = 20.0f, float fDepth = 20.0f);
	virtual ~CSkyBoxMesh();
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
class CStandardMesh : public CMesh
{
public:
	CStandardMesh(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList);
	virtual ~CStandardMesh();

protected:
	XMFLOAT4						*m_pxmf4Colors = NULL;
	XMFLOAT3						*m_pxmf3Normals = NULL;
	XMFLOAT3						*m_pxmf3Tangents = NULL;
	XMFLOAT3						*m_pxmf3BiTangents = NULL;
	XMFLOAT2						*m_pxmf2TextureCoords0 = NULL;
	XMFLOAT2						*m_pxmf2TextureCoords1 = NULL;

	ID3D12Resource					*m_pd3dColorBuffer = NULL;
	ID3D12Resource					*m_pd3dColorUploadBuffer = NULL;
	D3D12_VERTEX_BUFFER_VIEW		m_d3dColorBufferView;

	ID3D12Resource					*m_pd3dTextureCoord0Buffer = NULL;
	ID3D12Resource					*m_pd3dTextureCoord0UploadBuffer = NULL;
	D3D12_VERTEX_BUFFER_VIEW		m_d3dTextureCoord0BufferView;

	ID3D12Resource					*m_pd3dTextureCoord1Buffer = NULL;
	ID3D12Resource					*m_pd3dTextureCoord1UploadBuffer = NULL;
	D3D12_VERTEX_BUFFER_VIEW		m_d3dTextureCoord1BufferView;

	ID3D12Resource					*m_pd3dNormalBuffer = NULL;
	ID3D12Resource					*m_pd3dNormalUploadBuffer = NULL;
	D3D12_VERTEX_BUFFER_VIEW		m_d3dNormalBufferView;

	ID3D12Resource					*m_pd3dTangentBuffer = NULL;
	ID3D12Resource					*m_pd3dTangentUploadBuffer = NULL;
	D3D12_VERTEX_BUFFER_VIEW		m_d3dTangentBufferView;

	ID3D12Resource					*m_pd3dBiTangentBuffer = NULL;
	ID3D12Resource					*m_pd3dBiTangentUploadBuffer = NULL;
	D3D12_VERTEX_BUFFER_VIEW		m_d3dBiTangentBufferView;

public:
	void LoadMeshFromFile(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, FILE *pInFile);

	virtual void ReleaseUploadBuffers();
	virtual void Render(ID3D12GraphicsCommandList *pd3dCommandList, int nSubSet);
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

class CHeightMapImage
{
private:
	BYTE						*m_pHeightMapPixels;

	int							m_nWidth;
	int							m_nLength;
	XMFLOAT3					m_xmf3Scale;

public:
	CHeightMapImage(LPCTSTR pFileName, int nWidth, int nLength, XMFLOAT3 xmf3Scale);
	~CHeightMapImage(void);

	float GetHeight(float x, float z, bool bReverseQuad = false);
	XMFLOAT3 GetHeightMapNormal(int x, int z);
	XMFLOAT3 GetScale() { return(m_xmf3Scale); }

	BYTE *GetHeightMapPixels() { return(m_pHeightMapPixels); }
	int GetHeightMapWidth() { return(m_nWidth); }
	int GetHeightMapLength() { return(m_nLength); }
};

class CHeightMapGridMesh : public CStandardMesh
{
protected:
	int							m_nWidth;
	int							m_nLength;
	XMFLOAT3					m_xmf3Scale;

	UINT						*m_pnTextureNumbers = NULL;

	ID3D12Resource				*m_pd3TextureNumberBuffer = NULL;
	ID3D12Resource				*m_pd3dTextureNumberUploadBuffer = NULL;
	D3D12_VERTEX_BUFFER_VIEW	m_d3dTextureNumberBufferView;

public:
	CHeightMapGridMesh(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, int xStart, int zStart, int nWidth, int nLength, XMFLOAT3 xmf3Scale = XMFLOAT3(1.0f, 1.0f, 1.0f), XMFLOAT4 xmf4Color = XMFLOAT4(1.0f, 1.0f, 0.0f, 0.0f), void *pContext0 = NULL, void *pContext1 = NULL);
	virtual ~CHeightMapGridMesh();

	XMFLOAT3 GetScale() { return(m_xmf3Scale); }
	int GetWidth() { return(m_nWidth); }
	int GetLength() { return(m_nLength); }

	virtual float OnGetHeight(int x, int z, void *pContext);
	virtual XMFLOAT4 OnGetColor(int x, int z, void *pContext);

	virtual void ReleaseUploadBuffers();
	virtual void Render(ID3D12GraphicsCommandList *pd3dCommandList, int nSubSet);
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

class CBillBoardObjectsMesh : public CMesh
{
protected:
	XMFLOAT2						*m_pxmf2Sizes = NULL;

	ID3D12Resource					*m_pd3dSizeBuffer = NULL;
	ID3D12Resource					*m_pd3dSizeUploadBuffer = NULL;
	D3D12_VERTEX_BUFFER_VIEW		m_d3dSizeBufferView;

	UINT							*m_pnTextureNumbers = NULL;

	ID3D12Resource					*m_pd3dTextureNumberBuffer = NULL;
	ID3D12Resource					*m_pd3dTextureNumberUploadBuffer = NULL;
	D3D12_VERTEX_BUFFER_VIEW		m_d3dTextureNumberBufferView;

public:
	CBillBoardObjectsMesh(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList);
	virtual ~CBillBoardObjectsMesh();

	virtual void ReleaseUploadBuffers();
	virtual void Render(ID3D12GraphicsCommandList *pd3dCommandList);
};

class CFlowerObjectsMesh : public CBillBoardObjectsMesh
{
public:
	CFlowerObjectsMesh(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, void *pContext);
	virtual ~CFlowerObjectsMesh();
};

class CTreeObjectsMesh : public CBillBoardObjectsMesh
{
public:
	CTreeObjectsMesh(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, void *pContext);
	virtual ~CTreeObjectsMesh();
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

class CRectMesh : public CStandardMesh
{
public:
	CRectMesh(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, float fWidth, float fHeight);
	virtual ~CRectMesh();

	virtual void Render(ID3D12GraphicsCommandList *pd3dCommandList, int nSubSet);
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

class CUIRect : public CMesh
{
protected:
	XMFLOAT2						*m_pxmf2Positions = NULL;

	XMFLOAT2						*m_pxmf2Sizes = NULL;

	ID3D12Resource					*m_pd3dSizeBuffer = NULL;
	ID3D12Resource					*m_pd3dSizeUploadBuffer = NULL;
	D3D12_VERTEX_BUFFER_VIEW		m_d3dSizeBufferView;

public:
	CUIRect(ID3D12Device *pd3dDevice, ID3D12GraphicsCommandList *pd3dCommandList, XMFLOAT2 xmf2Center, XMFLOAT2 xmf2Size);
	virtual ~CUIRect();

	void ReleaseUploadBuffers();
	virtual void Render(ID3D12GraphicsCommandList *pd3dCommandList, UINT nInstances = 1);
};
