// ================================================================================
// == This file is a part of Tinkerbell UI Toolkit. (C) 2011-2012, Emil Seger�s ==
// ==                   See tinkerbell.h for more information.                   ==
// ================================================================================

#ifndef TB_FONT_RENDERER_H
#define TB_FONT_RENDERER_H

#include "tinkerbell.h"
#include "tb_bitmap_fragment.h"
#include "tb_renderer.h"
#include "tb_tempbuffer.h"
#include "tb_linklist.h"
#include "utf8/utf8.h"

namespace tinkerbell {

class TBBitmap;
class TBFontFace;

/** TBFontGlyphData is rendering info used during glyph rendering by TBFontRenderer.
	It does not own the data pointers. */
class TBFontGlyphData
{
public:
	TBFontGlyphData() : data8(nullptr), data32(nullptr), w(0), h(0), stride(0), rgb(false) {}
	~TBFontGlyphData() {}

	uint8 *data8;
	uint32 *data32;
	int w, h, stride;
	bool rgb;
};

/** TBGlyphMetrics contains metrics for a font glyph. */
class TBGlyphMetrics
{
public:
	TBGlyphMetrics() : advance(0), x(0), y(0) {}
	int16 advance, x, y;
};

/** TBFontMetrics contains metrics for a font face. */
class TBFontMetrics
{
public:
	TBFontMetrics() : ascent(0), descent(0), height(0) {}
	int16 ascent;			///< Ascent. See TBFontFace::GetAscent()
	int16 descent;			///< Descent. See TBFontFace::GetDescent()
	int16 height;			///< Height. See TBFontFace::GetHeight()
};

/** TBFontRenderer renders glyphs from a font file. */
class TBFontRenderer : public TBLinkOf<TBFontRenderer>
{
public:
	virtual ~TBFontRenderer() {}

	/** Open the given font file with this renderer and return a new TBFontFace with it.
		return nullptr if the file can't be opened by this renderer. */
	virtual TBFontFace *Create(const char *filename, int size) = 0;

	virtual bool RenderGlyph(TBFontGlyphData *data, UCS4 cp) = 0;
	virtual void GetGlyphMetrics(TBGlyphMetrics *metrics, UCS4 cp) = 0;
	virtual TBFontMetrics GetMetrics() = 0;
	//virtual int GetKernAdvance(UCS4 cp1, UCS4 cp2) = 0;
};

/** TBFontGlyph holds glyph metrics and bitmap fragment.
	There's one of theese for all rendered (both successful
	and missing) glyphs in TBFontFace. */
class TBFontGlyph
{
public:
	TBGlyphMetrics metrics;		///< The glyph metrics.
	TBBitmapFragment *frag;		///< The bitmap fragment, or nullptr if missing.
	bool has_rgb;				///< if true, drawing should ignore text color.
};

/** TBFontEffect applies an effect on each glyph that is rendered in a TBFontFace. */
class TBFontEffect
{
public:
	TBFontEffect();
	~TBFontEffect();

	/** Set blur radius. 0 means no blur. */
	void SetBlurRadius(int blur_radius);

	/** Returns true if the result is in RGB and should not be painted using the color parameter
		given to DrawString. In other words: It's a color glyph. */
	bool RendersInRGB() const { return false; }

	TBFontGlyphData *Render(TBGlyphMetrics *metrics, const TBFontGlyphData *src);
private:
	// Blur data
	int m_blur_radius;
	float *m_tempBuffer;
	float *m_kernel;
	TBTempBuffer m_blur_temp;
};

/** TBFontFace represents a loaded font that can measure and render strings. */
class TBFontFace : private TBRendererListener
{
public:
	TBFontFace(TBFontRenderer *renderer, int size);
	~TBFontFace();

	/** Render all glyphs needed to display the string. */
	bool RenderGlyphs(const char *glyph_str);

	/** Get the vertical distance (positive) from the horizontal baseline to the highest �character� coordinate
		in a font face. */
	int GetAscent() const { return m_metrics.ascent; }

	/** Get the vertical distance (positive) from the horizontal baseline to the lowest �character� coordinate
		in the font face. */
	int GetDescent() const { return m_metrics.descent; }

	/** Get height of the font in pixels. */
	int GetHeight() const { return m_metrics.height; }

	/** Get the effect object, so the effect can be changed.
		Note: No glyphs are re-rendered. Only new glyphs are affected. */
	TBFontEffect *GetEffect() { return &m_effect; }

	/** Draw string at position x, y (marks the upper left corner of the text). */
	void DrawString(int x, int y, const TBColor &color, const char *str, int len = TB_ALL_TO_TERMINATION);

	/** Measure the width of the given string. Should measure len characters or to the null
		termination (whatever comes first). */
	int GetStringWidth(const char *str, int len = TB_ALL_TO_TERMINATION);

#ifdef _DEBUG
	/** Render the glyph bitmaps on screen, to analyze fragment positioning. */
	void Debug();
#endif

	// Implementing TBRendererListener
	virtual void OnContextLost();
	virtual void OnContextRestored();
private:
	TBFontGlyph *GetGlyph(int cp, bool create_if_needed);
	TBBitmapFragmentManager m_frag_manager;
	TBHashTableOf<TBFontGlyph> m_glyphs;
	TBFontRenderer *m_font_renderer;
	TBFontMetrics m_metrics;
	TBFontEffect m_effect;
};

/** TBFontInfo provides information about a font file associated with a font index. */
class TBFontInfo
{
public:
	/** Get the filename. */
	const char *GetFilename() const { return m_filename; }

	/** Return the index that can be used to create this from a
		TBFontDescription (See TBFontDescription::SetIndex) */
	uint32 GetIndex() const { return m_index; }
private:
	friend class TBFontManager;
	TBFontInfo(const char *filename, uint32 index) : m_filename(filename), m_index(index) {}
	TBStr m_filename;
	uint32 m_index;
};

/** TBFontManager creates and owns font faces (TBFontFace) which are looked up from
	TBFontDescription using GetFontFace.

	The fonts it can return must first have their file added and indexed (AddFontInfo),
	and then created CreateFontFace. Otherwise when asking for a font and it doesn't
	exist, it will use the default font.

	Font index 0 is always populated with a dummy font, that draws squares. This font
	is generally not used for other things than testing or when there is no font backend
	implemented yet. Since there is always at least the test font, no nullptr checks are
	needed.
*/
class TBFontManager
{
public:
	TBFontManager();
	~TBFontManager();

	/** Add a renderer so fonts supported by the renderer can be created. Ownership of the
		renderer is taken, until calling RemoveRenderer. */
	void AddRenderer(TBFontRenderer *renderer) { m_font_renderers.AddLast(renderer); }
	void RemoveRenderer(TBFontRenderer *renderer) { m_font_renderers.Remove(renderer); }

	/** Add TBFontInfo for the given font filename, so it can be loaded and identified
		using the font index in a TBFontDescription. */
	TBFontInfo *AddFontInfo(const char *filename);

	/** Get TBFontInfo for the given font index. */
	TBFontInfo *GetFontInfo(uint32 index);

	/** Return true if there is a font loaded that match the given font description. */
	bool HasFontFace(const TBFontDescription &font_desc);

	/** Get a loaded font matching the description, or the default font if there is no exact match.
		If there is not even any default font loaded, it will return the test dummy font (rendering
		only squares). */
	TBFontFace *GetFontFace(const TBFontDescription &font_desc);

	/** Create and add a font with the given description. Returns the created font face, or
		nullptr on fail. The font is owned by this TBFontManager, and can be recieved from
		GetFontFace using the same TBFontDescription. */
	TBFontFace *CreateFontFace(const TBFontDescription &font_desc);

	/** Set the default font description. This is the font description that will be used by default
		for widgets. By default, the default description is using the test dummy font. */
	void SetDefaultFontDescription(const TBFontDescription &font_desc) { m_default_font_desc = font_desc; }
	TBFontDescription GetDefaultFontDescription() const { return m_default_font_desc; }
private:
	TBListAutoDeleteOf<TBFontInfo> m_font_info;
	TBHashTableAutoDeleteOf<TBFontFace> m_fonts;
	TBLinkListAutoDeleteOf<TBFontRenderer> m_font_renderers;
	TBFontDescription m_default_font_desc;
	TBFontDescription m_test_font_desc;
};

}; // namespace tinkerbell

#endif // TB_FONT_RENDERER_H