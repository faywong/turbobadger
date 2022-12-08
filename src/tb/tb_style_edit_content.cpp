// ================================================================================
// ==      This file is a part of Turbo Badger. (C) 2011-2014, Emil Segerås      ==
// ==                     See tb_core.h for more information.                    ==
// ================================================================================

#include <cstdio>
#include "tb_style_edit.h"
#include "tb_style_edit_content.h"
#include "tb_font_renderer.h"
#include <assert.h>

namespace tb {

// == TBTextFragmentContentFactory ==========================================================================

int TBTextFragmentContentFactory::GetContent(const char *text)
{
	if (text[0] == '<')
	{
		int i = 0;
		while (text[i] != '>' && text[i] > 31)
			i++;
		if (text[i] == '>')
		{
			i++;
			return i;
		}
	}
	return 0;
}

TBTextFragmentContent *TBTextFragmentContentFactory::CreateFragmentContent(const char *text, int text_len)
{
	uint32_t size;
	if (strncmp(text, "<hr>", text_len) == 0)
		return new TBTextFragmentContentHR(100, 2);
	else if (strncmp(text, "<u>", text_len) == 0)
		return new TBTextFragmentContentUnderline();
	else if (strncmp(text, "<s>", text_len) == 0)
        return new TBTextFragmentContentStrikethrough();
    else if (strncmp(text, "<sup>", text_len) == 0)
		return new TBTextFragmentContentSuperscript();
	else if (strncmp(text, "<sub>", text_len) == 0)
		return new TBTextFragmentContentSubscript();
	else if (strncmp(text, "<color ", MIN(text_len, 7)) == 0)
	{
		TBColor color;
		color.SetFromString(TBStr(text + 7, text_len - 8));
		return new TBTextFragmentContentTextColor(color);
	}
	else if (1 == sscanf(text, "<size %u>", &size))
	{
		return new TBTextFragmentContentTextSize(size);
	}
	else if (strncmp(text, "</", MIN(text_len, 2)) == 0)
		return new TBTextFragmentContentStylePop();
	return nullptr;
}

// == PHorizontalLineContent ================================================================================

TBTextFragmentContentHR::TBTextFragmentContentHR(int32_t width_in_percent, int32_t height)
	: width_in_percent(width_in_percent)
	, height(height)
{
}

void TBTextFragmentContentHR::Paint(TBTextFragment *fragment, int32_t translate_x, int32_t translate_y, TBTextProps *props)
{
	int x = translate_x + fragment->xpos;
	int y = translate_y + fragment->ypos;

	int w = fragment->block->styledit->layout_width * width_in_percent / 100;
	x += (fragment->block->styledit->layout_width - w) / 2;

	TBStyleEditListener *listener = fragment->block->styledit->listener;
	listener->DrawRectFill(TBRect(x, y, w, height), props->data->text_color);
}

int32_t TBTextFragmentContentHR::GetWidth(TBFontFace * /*font*/, TBTextFragment * fragment)
{
	return MAX(fragment->block->styledit->layout_width, 0);
}

int32_t TBTextFragmentContentHR::GetHeight(TBFontFace * /*font*/, TBTextFragment * /*fragment*/) { return height; }

#if 0
int32_t TBTextFragmentContentTextSize::GetWidth(TBFontFace * font, TBTextFragment * fragment)
{
	return font->
}
int32_t TBTextFragmentContentTextSize::GetHeight(TBFontFace * font, TBTextFragment * /*fragment*/)
{
	return font->GetHeight();
}
#endif

// ============================================================================

void TBTextFragmentContentUnderline::Paint(TBTextFragment * /*fragment*/, int32_t /*translate_x*/, int32_t /*translate_y*/, TBTextProps * props)
{
	if (TBTextProps::Data *data = props->Push())
		data->underline = true;
}

void TBTextFragmentContentStrikethrough::Paint(TBTextFragment * /*fragment*/, int32_t /*translate_x*/, int32_t /*translate_y*/, TBTextProps * props)
{
    if (TBTextProps::Data *data = props->Push())
        data->strikethrough = true;
}

void TBTextFragmentContentTextColor::Paint(TBTextFragment * /*fragment*/, int32_t /*translate_x*/, int32_t /*translate_y*/, TBTextProps * props)
{
	if (TBTextProps::Data *data = props->Push())
		data->text_color = color;
}

void TBTextFragmentContentTextSize::Paint(TBTextFragment * /*fragment*/, int32_t /*translate_x*/, int32_t /*translate_y*/, TBTextProps * props)
{
	if (TBTextProps::Data *data = props->Push())
		data->font_desc.SetSize(_size);
}

void TBTextFragmentContentStylePop::Paint(TBTextFragment * /*fragment*/, int32_t /*translate_x*/, int32_t /*translate_y*/, TBTextProps *props)
{
	props->Pop();
}

} // namespace tb
