// Harmonia uxTheme declarations.
// Autor: Davidoff Dmitry

module uxTheme;

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.aclapi;
import win32.commctrl;
pragma(lib, "uxthemed.lib");


//---------------------------------------------------------------------------
//
// File   : uxtheme.d
// Version: 1.0

//---------------------------------------------------------------------------
//#include <commctrl.h>
//---------------------------------------------------------------------------
// Define API decoration for direct importing of DLL references.

/*
   #ifndef THEMEAPI
   #if !defined(_UXTHEME_)
   #define THEMEAPI          EXTERN_C DECLSPEC_IMPORT HRESULT STDAPICALLTYPE
   #define THEMEAPI_(type)   EXTERN_C DECLSPEC_IMPORT type STDAPICALLTYPE
   #else
   #define THEMEAPI          STDAPI
   #define THEMEAPI_(type)   STDAPI_(type)
   #endif
   #endif // THEMEAPI
 */

//---------------------------------------------------------------------------

alias HANDLE HTHEME;          // handle to a section of theme data for class

//alias HANDLE HIMAGELIST;      // HIMAGELIST must be defined in win32.d.

enum : HRESULT
{
    S_OK = cast(HRESULT)0,
}

//export
extern (Windows)
{
//---------------------------------------------------------------------------
// NOTE: PartId's and StateId's used in the theme API are defined in the
//       hdr file <tmschema.h> using the TM_PART and TM_STATE macros.  For
//       example, "TM_PART(BP, PUSHBUTTON)" defines the PartId "BP_PUSHBUTTON".

//---------------------------------------------------------------------------
//  OpenThemeData()     - Open the theme data for the specified HWND and
//                        semi-colon separated list of class names.
//
//                        OpenThemeData() will try each class name, one at
//                        a time, and use the first matching theme info
//                        found.  If a match is found, a theme handle
//                        to the data is returned.  If no match is found,
//                        a "NULL" handle is returned.
//
//                        When the window is destroyed or a WM_THEMECHANGED
//                        msg is received, "CloseThemeData()" should be
//                        called to close the theme handle.
//
//  hwnd                - window handle of the control/window to be themed
//
//  pszClassList        - class name (or list of names) to match to theme data
//                        section.  if the list contains more than one name,
//                        the names are tested one at a time for a match.
//                        If a match is found, OpenThemeData() returns a
//                        theme handle associated with the matching class.
//                        This param is a list (instead of just a single
//                        class name) to provide the class an opportunity
//                        to get the "best" match between the class and
//                        the current theme.  For example, a button might
//                        pass L"OkButton, Button" if its ID=ID_OK.  If
//                        the current theme has an entry for OkButton,
//                        that will be used.  Otherwise, we fall back on
//                        the normal Button entry.
//---------------------------------------------------------------------------
HTHEME OpenThemeData(HWND, LPCWSTR classList);

alias HTHEME function(HWND, LPCWSTR classList) type_OpenThemeData;

//---------------------------------------------------------------------------
//  CloseTHemeData()    - closes the theme data handle.  This should be done
//                        when the window being themed is destroyed or
//                        whenever a WM_THEMECHANGED msg is received
//                        (followed by an attempt to create a new Theme data
//                        handle).
//
//  hTheme              - open theme data handle (returned from prior call
//                        to OpenThemeData() API).
//---------------------------------------------------------------------------
HRESULT CloseThemeData(HTHEME hTheme);

alias HRESULT function(HTHEME hTheme) type_CloseThemeData;

//---------------------------------------------------------------------------
//    functions for basic drawing support
//---------------------------------------------------------------------------
// The following methods are the theme-aware drawing services.
// Controls/Windows are defined in drawable "parts" by their author: a
// parent part and 0 or more child parts.  Each of the parts can be
// described in "states" (ex: disabled, hot, pressed).
//---------------------------------------------------------------------------
// For the list of all themed classes and the definition of all
// parts and states, see the file "tmschmea.h".
//---------------------------------------------------------------------------
// Each of the below methods takes a "iPartId" param to specify the
// part and a "iStateId" to specify the state of the part.
// "iStateId=0" refers to the root part.  "iPartId" = "0" refers to
// the root class.
//-----------------------------------------------------------------------
// Note: draw operations are always scaled to fit (and not to exceed)
// the specified "Rect".
//-----------------------------------------------------------------------

//------------------------------------------------------------------------
//  DrawThemeBackground()
//                      - draws the theme-specified border and fill for
//                        the "iPartId" and "iStateId".  This could be
//                        based on a bitmap file, a border and fill, or
//                        other image description.
//
//  hTheme              - theme data handle
//  hdc                 - HDC to draw into
//  iPartId             - part number to draw
//  iStateId            - state number (of the part) to draw
//  pRect               - defines the size/location of the part
//  pClipRect           - optional clipping rect (don't draw outside it)
//------------------------------------------------------------------------
HRESULT DrawThemeBackground(HTHEME hTheme, HDC hdc, int iPartId, int iStateId
                            , in RECT* pRect, /*OPTIONAL*/ in RECT* pClipRect);

alias HRESULT function(HTHEME hTheme, HDC hdc, int iPartId, int iStateId
                       , in RECT* pRect, /*OPTIONAL*/ in RECT* pClipRect) type_DrawThemeBackground;

//---------------------------------------------------------------------------
//----- DrawThemeText() flags ----

const int DTT_GRAYED = 1;     // draw a grayed-out string

//-------------------------------------------------------------------------
//  DrawThemeText()     - draws the text using the theme-specified
//                        color and font for the "iPartId" and
//                        "iStateId".
//
//  hTheme              - theme data handle
//  hdc                 - HDC to draw into
//  iPartId             - part number to draw
//  iStateId            - state number (of the part) to draw
//  pszText             - actual text to draw
//  dwCharCount         - number of chars to draw (-1 for all)
//  dwTextFlags         - same as DrawText() "uFormat" param
//  dwTextFlags2        - additional drawing options
//  pRect               - defines the size/location of the part
//-------------------------------------------------------------------------
HRESULT DrawThemeText(HTHEME hTheme, HDC hdc, int iPartId
                      , int iStateId, LPCWSTR pszText, int iCharCount
                      , DWORD dwTextFlags, DWORD dwTextFlags2, in RECT* pRect);

alias HRESULT function(HTHEME hTheme, HDC hdc, int iPartId
                       , int iStateId, LPCWSTR pszText, int iCharCount
                       , DWORD dwTextFlags, DWORD dwTextFlags2, in RECT* pRect) type_DrawThemeText;

//-------------------------------------------------------------------------
//  GetThemeBackgroundContentRect()
//                      - gets the size of the content for the theme-defined
//                        background.  This is usually the area inside
//                        the borders or Margins.
//
//      hTheme          - theme data handle
//      hdc             - (optional) device content to be used for drawing
//      iPartId         - part number to draw
//      iStateId        - state number (of the part) to draw
//      pBoundingRect   - the outer RECT of the part being drawn
//      pContentRect    - RECT to receive the content area
//-------------------------------------------------------------------------
HRESULT GetThemeBackgroundContentRect(HTHEME hTheme, /*OPTIONAL*/ HDC hdc
                                      , int iPartId, int iStateId, in RECT* pBoundingRect
                                      , /*out*/ RECT* pContentRect);

alias HRESULT function(HTHEME hTheme, /*OPTIONAL*/ HDC hdc
                       , int iPartId, int iStateId, in RECT* pBoundingRect
                       , /*out*/ RECT* pContentRect) type_GetThemeBackgroundContentRect;

//-------------------------------------------------------------------------
//  GetThemeBackgroundExtent() - calculates the size/location of the theme-
//                               specified background based on the
//                               "pContentRect".
//
//      hTheme          - theme data handle
//      hdc             - (optional) device content to be used for drawing
//      iPartId         - part number to draw
//      iStateId        - state number (of the part) to draw
//      pContentRect    - RECT that defines the content area
//      pBoundingRect   - RECT to receive the overall size/location of part
//-------------------------------------------------------------------------
HRESULT GetThemeBackgroundExtent(HTHEME hTheme, /*OPTIONAL*/ HDC hdc
                                 , int iPartId, int iStateId, in RECT* pContentRect
                                 , /*out*/ RECT* pExtentRect);

alias HRESULT function(HTHEME hTheme, /*OPTIONAL*/ HDC hdc
                       , int iPartId, int iStateId, in RECT* pContentRect
                       , /*out*/ RECT* pExtentRect) type_GetThemeBackgroundExtent;

//-------------------------------------------------------------------------
enum THEMESIZE
{
    TS_MIN,                 // minimum size
    TS_TRUE,                // size without stretching
    TS_DRAW,                // size that theme mgr will use to draw part
};

//-------------------------------------------------------------------------
//  GetThemePartSize() - returns the specified size of the theme part
//
//  hTheme              - theme data handle
//  hdc                 - HDC to select font into & measure against
//  iPartId             - part number to retrieve size for
//  iStateId            - state number (of the part)
//  prc                 - (optional) rect for part drawing destination
//  eSize               - the type of size to be retreived
//  psz                 - receives the specified size of the part
//-------------------------------------------------------------------------
HRESULT GetThemePartSize(HTHEME hTheme, HDC hdc, int iPartId, int iStateId
                         , /*OPTIONAL*/ RECT* prc, THEMESIZE eSize, /*out*/ SIZE* psz);

alias HRESULT function(HTHEME hTheme, HDC hdc, int iPartId, int iStateId
                       , /*OPTIONAL*/ RECT* prc, THEMESIZE eSize, /*out*/ SIZE* psz) type_GetThemePartSize;

//-------------------------------------------------------------------------
//  GetThemeTextExtent() - calculates the size/location of the specified
//                         text when rendered in the Theme Font.
//
//  hTheme              - theme data handle
//  hdc                 - HDC to select font & measure into
//  iPartId             - part number to draw
//  iStateId            - state number (of the part)
//  pszText             - the text to be measured
//  dwCharCount         - number of chars to draw (-1 for all)
//  dwTextFlags         - same as DrawText() "uFormat" param
//  pszBoundingRect     - optional: to control layout of text
//  pszExtentRect       - receives the RECT for text size/location
//-------------------------------------------------------------------------
HRESULT GetThemeTextExtent(HTHEME hTheme, HDC hdc
                           , int iPartId, int iStateId, LPCWSTR pszText, int iCharCount
                           , DWORD dwTextFlags, /*OPTIONAL*/ in RECT* pBoundingRect
                           , /*out*/ RECT* pExtentRect);

alias HRESULT function(HTHEME hTheme, HDC hdc
                       , int iPartId, int iStateId, LPCWSTR pszText, int iCharCount
                       , DWORD dwTextFlags, /*OPTIONAL*/ in RECT* pBoundingRect
                       , /*out*/ RECT* pExtentRect) type_GetThemeTextExtent;

//-------------------------------------------------------------------------
//  GetThemeTextMetrics()
//                      - returns info about the theme-specified font
//                        for the part/state passed in.
//
//  hTheme              - theme data handle
//  hdc                 - optional: HDC for screen context
//  iPartId             - part number to draw
//  iStateId            - state number (of the part)
//  ptm                 - receives the font info
//-------------------------------------------------------------------------
HRESULT GetThemeTextMetrics(HTHEME hTheme, /*OPTIONAL*/ HDC hdc
                            , int iPartId, int iStateId, /*out*/ TEXTMETRICW* ptm);

alias HRESULT function(HTHEME hTheme, /*OPTIONAL*/ HDC hdc
                       , int iPartId, int iStateId, /*out*/ TEXTMETRICW* ptm) type_GetThemeTextMetrics;

//-------------------------------------------------------------------------
//  GetThemeBackgroundRegion()
//                      - computes the region for a regular or partially
//                        transparent theme-specified background that is
//                        bound by the specified "pRect".
//                        If the rectangle is empty, sets the HRGN to NULL
//                        and return S_FALSE.
//
//  hTheme              - theme data handle
//  hdc                 - optional HDC to draw into (DPI scaling)
//  iPartId             - part number to draw
//  iStateId            - state number (of the part)
//  pRect               - the RECT used to draw the part
//  pRegion             - receives handle to calculated region
//-------------------------------------------------------------------------
HRESULT GetThemeBackgroundRegion(HTHEME hTheme, /*OPTIONAL*/ HDC hdc
                                 , int iPartId, int iStateId
                                 , in RECT* pRect, /*out*/ HRGN* pRegion);

alias HRESULT function(HTHEME hTheme, /*OPTIONAL*/ HDC hdc
                       , int iPartId, int iStateId
                       , in RECT* pRect, /*out*/ HRGN* pRegion) type_GetThemeBackgroundRegion;

//-------------------------------------------------------------------------
//----- HitTestThemeBackground, HitTestThemeBackgroundRegion flags ----

//  Theme background segment hit test flag (default). possible return values are:
//  HTCLIENT: hit test succeeded in the middle background segment
//  HTTOP, HTLEFT, HTTOPLEFT, etc:  // hit test succeeded in the the respective theme background segment.
enum : uint
{
    HTTB_BACKGROUNDSEG = 0x000,

    //  Fixed border hit test option.  possible return values are:
    //  HTCLIENT: hit test succeeded in the middle background segment
    //  HTBORDER: hit test succeeded in any other background segment
    HTTB_FIXEDBORDER = 0x0002,                // Return code may be either HTCLIENT or HTBORDER.

    //  Caption hit test option.  Possible return values are:
    //  HTCAPTION: hit test succeeded in the top, top left, or top right background segments
    //  HTNOWHERE or another return code, depending on absence or presence of accompanying flags, resp.
    HTTB_CAPTION = 0x0004,

    //  Resizing border hit test flags.  Possible return values are:
    //  HTCLIENT: hit test succeeded in middle background segment
    //  HTTOP, HTTOPLEFT, HTLEFT, HTRIGHT, etc:    hit test succeeded in the respective system resizing zone
    //  HTBORDER: hit test failed in middle segment and resizing zones, but succeeded in a background border segment
    HTTB_RESIZINGBORDER_LEFT   = 0x0010,      // Hit test left resizing border,
    HTTB_RESIZINGBORDER_TOP    = 0x0020,      // Hit test top resizing border
    HTTB_RESIZINGBORDER_RIGHT  = 0x0040,      // Hit test right resizing border
    HTTB_RESIZINGBORDER_BOTTOM = 0x0080,      // Hit test bottom resizing border

    HTTB_RESIZINGBORDER = HTTB_RESIZINGBORDER_LEFT | HTTB_RESIZINGBORDER_TOP | HTTB_RESIZINGBORDER_RIGHT | HTTB_RESIZINGBORDER_BOTTOM,

    // Resizing border is specified as a template, not just window edges.
    // This option is mutually exclusive with HTTB_SYSTEMSIZINGWIDTH; HTTB_SIZINGTEMPLATE takes precedence
    HTTB_SIZINGTEMPLATE = 0x0100,

    // Use system resizing border width rather than theme content margins.
    // This option is mutually exclusive with HTTB_SIZINGTEMPLATE, which takes precedence.
    HTTB_SYSTEMSIZINGMARGINS = 0x0200,
};

//-------------------------------------------------------------------------
//  HitTestThemeBackground()
//                      - returns a HitTestCode (a subset of the values
//                        returned by WM_NCHITTEST) for the point "ptTest"
//                        within the theme-specified background
//                        (bound by pRect).  "pRect" and "ptTest" should
//                        both be in the same coordinate system
//                        (client, screen, etc).
//
//      hTheme          - theme data handle
//      hdc             - HDC to draw into
//      iPartId         - part number to test against
//      iStateId        - state number (of the part)
//      pRect           - the RECT used to draw the part
//      hrgn            - optional region to use; must be in same coordinates as
//                      -    pRect and pTest.
//      ptTest          - the hit point to be tested
//      dwOptions       - HTTB_xxx constants
//      pwHitTestCode   - receives the returned hit test code - one of:
//
//                        HTNOWHERE, HTLEFT, HTTOPLEFT, HTBOTTOMLEFT,
//                        HTRIGHT, HTTOPRIGHT, HTBOTTOMRIGHT,
//                        HTTOP, HTBOTTOM, HTCLIENT
//-------------------------------------------------------------------------
HRESULT HitTestThemeBackground(HTHEME hTheme, /*OPTIONAL*/ HDC hdc, int iPartId
                               , int iStateId, DWORD dwOptions, in RECT* pRect
                               , /*OPTIONAL*/ HRGN hrgn, POINT ptTest, /*out*/ WORD* pwHitTestCode);

alias HRESULT function(HTHEME hTheme, /*OPTIONAL*/ HDC hdc, int iPartId
                       , int iStateId, DWORD dwOptions, in RECT* pRect
                       , /*OPTIONAL*/ HRGN hrgn, POINT ptTest, /*out*/ WORD* pwHitTestCode) type_HitTestThemeBackground;

//------------------------------------------------------------------------
//  DrawThemeEdge()     - Similar to the DrawEdge() API, but uses part colors
//                        and is high-DPI aware
//  hTheme              - theme data handle
//  hdc                 - HDC to draw into
//  iPartId             - part number to draw
//  iStateId            - state number of part
//  pDestRect           - the RECT used to draw the line(s)
//  uEdge               - Same as DrawEdge() API
//  uFlags              - Same as DrawEdge() API
//  pContentRect        - Receives the interior rect if (uFlags & BF_ADJUST)
//------------------------------------------------------------------------
HRESULT DrawThemeEdge(HTHEME hTheme, HDC hdc, int iPartId, int iStateId
                      , in RECT* pDestRect, UINT uEdge, UINT uFlags
                      , /*OPTIONAL*/ /*out*/ RECT* pContentRect);

alias HRESULT function(HTHEME hTheme, HDC hdc, int iPartId, int iStateId
                       , in RECT* pDestRect, UINT uEdge, UINT uFlags
                       , /*OPTIONAL*/ /*out*/ RECT* pContentRect) type_DrawThemeEdge;

//------------------------------------------------------------------------
//  DrawThemeIcon()     - draws an image within an imagelist based on
//                        a (possible) theme-defined effect.
//
//  hTheme              - theme data handle
//  hdc                 - HDC to draw into
//  iPartId             - part number to draw
//  iStateId            - state number of part
//  pRect               - the RECT to draw the image within
//  himl                - handle to IMAGELIST
//  iImageIndex         - index into IMAGELIST (which icon to draw)
//------------------------------------------------------------------------
HRESULT DrawThemeIcon(HTHEME hTheme, HDC hdc, int iPartId
                      , int iStateId, in RECT* pRect
                      , HIMAGELIST himl, int iImageIndex);

alias HRESULT function(HTHEME hTheme, HDC hdc, int iPartId
                       , int iStateId, in RECT* pRect
                       , HIMAGELIST himl, int iImageIndex) type_DrawThemeIcon;

//---------------------------------------------------------------------------
//  IsThemePartDefined() - returns TRUE if the theme has defined parameters
//                         for the specified "iPartId" and "iStateId".
//
//  hTheme              - theme data handle
//  iPartId             - part number to find definition for
//  iStateId            - state number of part
//---------------------------------------------------------------------------
BOOL IsThemePartDefined(HTHEME hTheme, int iPartId, int iStateId);

alias BOOL function(HTHEME hTheme, int iPartId, int iStateId) type_IsThemePartDefined;

//---------------------------------------------------------------------------
//  IsThemeBackgroundPartiallyTransparent()
//                      - returns TRUE if the theme specified background for
//                        the part/state has transparent pieces or
//                        alpha-blended pieces.
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//---------------------------------------------------------------------------
BOOL IsThemeBackgroundPartiallyTransparent(HTHEME hTheme, int iPartId, int iStateId);

alias BOOL function(HTHEME hTheme, int iPartId, int iStateId) type_IsThemeBackgroundPartiallyTransparent;

//---------------------------------------------------------------------------
//    lower-level theme information services
//---------------------------------------------------------------------------
// The following methods are getter routines for each of the Theme Data types.
// Controls/Windows are defined in drawable "parts" by their author: a
// parent part and 0 or more child parts.  Each of the parts can be
// described in "states" (ex: disabled, hot, pressed).
//---------------------------------------------------------------------------
// Each of the below methods takes a "iPartId" param to specify the
// part and a "iStateId" to specify the state of the part.
// "iStateId=0" refers to the root part.  "iPartId" = "0" refers to
// the root class.
//-----------------------------------------------------------------------
// Each method also take a "iPropId" param because multiple instances of
// the same primitive type can be defined in the theme schema.
//-----------------------------------------------------------------------

//-----------------------------------------------------------------------
//  GetThemeColor()     - Get the value for the specified COLOR property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pColor              - receives the value of the property
//-----------------------------------------------------------------------
HRESULT GetThemeColor(HTHEME hTheme, int iPartId, int iStateId
                      , int iPropId, /*out*/ COLORREF* pColor);

alias HRESULT function(HTHEME hTheme, int iPartId, int iStateId
                       , int iPropId, /*out*/ COLORREF* pColor) type_GetThemeColor;

//-----------------------------------------------------------------------
//  GetThemeMetric()    - Get the value for the specified metric/size
//                        property
//
//  hTheme              - theme data handle
//  hdc                 - (optional) hdc to be drawn into (DPI scaling)
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  piVal               - receives the value of the property
//-----------------------------------------------------------------------
HRESULT GetThemeMetric(HTHEME hTheme, /*OPTIONAL*/ HDC hdc, int iPartId
                       , int iStateId, int iPropId, /*out*/ int* piVal);

alias HRESULT function(HTHEME hTheme, /*OPTIONAL*/ HDC hdc, int iPartId
                       , int iStateId, int iPropId, /*out*/ int* piVal) type_GetThemeMetric;

//-----------------------------------------------------------------------
//  GetThemeString()    - Get the value for the specified string property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pszBuff             - receives the string property value
//  cchMaxBuffChars     - max. number of chars allowed in pszBuff
//-----------------------------------------------------------------------
HRESULT GetThemeString(HTHEME hTheme, int iPartId
                       , int iStateId, int iPropId
                       , /*out*/ LPWSTR pszBuff, int cchMaxBuffChars);

alias HRESULT function(HTHEME hTheme, int iPartId
                       , int iStateId, int iPropId
                       , /*out*/ LPWSTR pszBuff, int cchMaxBuffChars) type_GetThemeString;

//-----------------------------------------------------------------------
//  GetThemeBool()      - Get the value for the specified BOOL property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pfVal               - receives the value of the property
//-----------------------------------------------------------------------
HRESULT GetThemeBool(HTHEME hTheme, int iPartId
                     , int iStateId, int iPropId, /*out*/ BOOL* pfVal);

alias HRESULT function(HTHEME hTheme, int iPartId
                       , int iStateId, int iPropId, /*out*/ BOOL* pfVal) type_GetThemeBool;

//-----------------------------------------------------------------------
//  GetThemeInt()       - Get the value for the specified int property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  piVal               - receives the value of the property
//-----------------------------------------------------------------------
HRESULT GetThemeInt(HTHEME hTheme, int iPartId
                    , int iStateId, int iPropId, /*out*/ BOOL* pfVal);

alias HRESULT function(HTHEME hTheme, int iPartId
                       , int iStateId, int iPropId, /*out*/ BOOL* pfVal) type_GetThemeInt;

//-----------------------------------------------------------------------
//  GetThemeEnumValue() - Get the value for the specified ENUM property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  piVal               - receives the value of the enum (cast to int*)
//-----------------------------------------------------------------------
HRESULT GetThemeEnumValue(HTHEME hTheme, int iPartId
                          , int iStateId, int iPropId, /*out*/ int* piVal);

alias HRESULT function(HTHEME hTheme, int iPartId
                       , int iStateId, int iPropId, /*out*/ int* piVal) type_GetThemeEnumValue;

//-----------------------------------------------------------------------
//  GetThemePosition()  - Get the value for the specified position
//                        property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pPoint              - receives the value of the position property
//-----------------------------------------------------------------------
HRESULT GetThemePosition(HTHEME hTheme, int iPartId
                         , int iStateId, int iPropId, /*out*/ POINT* pPoint);

alias HRESULT function(HTHEME hTheme, int iPartId
                       , int iStateId, int iPropId, /*out*/ POINT* pPoint) type_GetThemePosition;

//-----------------------------------------------------------------------
//  GetThemeFont()      - Get the value for the specified font property
//
//  hTheme              - theme data handle
//  hdc                 - (optional) hdc to be drawn to (DPI scaling)
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pFont               - receives the value of the LOGFONT property
//                        (scaled for the current logical screen dpi)
//-----------------------------------------------------------------------
HRESULT GetThemeFont(HTHEME hTheme, /*OPTIONAL*/ HDC hdc, int iPartId
                     , int iStateId, int iPropId, /*out*/ LOGFONTW* pFont);

alias HRESULT function(HTHEME hTheme, /*OPTIONAL*/ HDC hdc, int iPartId
                       , int iStateId, int iPropId, /*out*/ LOGFONTW* pFont) type_GetThemeFont;

//-----------------------------------------------------------------------
//  GetThemeRect()      - Get the value for the specified RECT property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pRect               - receives the value of the RECT property
//-----------------------------------------------------------------------
HRESULT GetThemeRect(HTHEME hTheme, int iPartId
                     , int iStateId, int iPropId, /*out*/ RECT* pRect);

alias HRESULT function(HTHEME hTheme, int iPartId
                       , int iStateId, int iPropId, /*out*/ RECT* pRect) type_GetThemeRect;

//-----------------------------------------------------------------------
struct MARGINS
{
    int cxLeftWidth;          // width of left border that retains its size
    int cxRightWidth;         // width of right border that retains its size
    int cyTopHeight;          // height of top border that retains its size
    int cyBottomHeight;       // height of bottom border that retains its size
};

alias MARGINS* PMARGINS;

//-----------------------------------------------------------------------
//  GetThemeMargins()   - Get the value for the specified MARGINS property
//
//      hTheme          - theme data handle
//      hdc             - (optional) hdc to be used for drawing
//      iPartId         - part number
//      iStateId        - state number of part
//      iPropId         - the property number to get the value for
//      prc             - RECT for area to be drawn into
//      pMargins        - receives the value of the MARGINS property
//-----------------------------------------------------------------------
HRESULT GetThemeMargins(HTHEME hTheme, /*OPTIONAL*/ HDC hdc
                        , int iPartId, int iStateId, int iPropId
                        , /*OPTIONAL*/ RECT* prc, /*out*/ MARGINS* pMargins);

alias HRESULT function(HTHEME hTheme, /*OPTIONAL*/ HDC hdc
                       , int iPartId, int iStateId, int iPropId
                       , /*OPTIONAL*/ RECT* prc, /*out*/ MARGINS* pMargins) type_GetThemeMargins;

//-----------------------------------------------------------------------
const uint MAX_INTLIST_COUNT = 10;

struct INTLIST
{
    int iValueCount;          // number of values in iValues
    int iValues[MAX_INTLIST_COUNT];
};

alias INTLIST* PINTLIST;

//-----------------------------------------------------------------------
//  GetThemeIntList()   - Get the value for the specified INTLIST struct
//
//      hTheme          - theme data handle
//      iPartId         - part number
//      iStateId        - state number of part
//      iPropId         - the property number to get the value for
//      pIntList        - receives the value of the INTLIST property
//-----------------------------------------------------------------------
HRESULT GetThemeIntList(HTHEME hTheme, int iPartId, int iStateId
                        , int iPropId, /*out*/ INTLIST* pIntList);

alias HRESULT function(HTHEME hTheme, int iPartId, int iStateId
                       , int iPropId, /*out*/ INTLIST* pIntList) type_GetThemeIntList;

//-----------------------------------------------------------------------
enum PROPERTYORIGIN
{
    PO_STATE,               // property was found in the state section
    PO_PART,                // property was found in the part section
    PO_CLASS,               // property was found in the class section
    PO_GLOBAL,              // property was found in [globals] section
    PO_NOTFOUND             // property was not found
};

//-----------------------------------------------------------------------
//  GetThemePropertyOrigin()
//                      - searches for the specified theme property
//                        and sets "pOrigin" to indicate where it was
//                        found (or not found)
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to search for
//  pOrigin             - receives the value of the property origin
//-----------------------------------------------------------------------
HRESULT GetThemePropertyOrigin(HTHEME hTheme, int iPartId, int iStateId
                               , int iPropId, /*out*/ PROPERTYORIGIN* pOrigin);

alias HRESULT function(HTHEME hTheme, int iPartId, int iStateId
                       , int iPropId, /*out*/ PROPERTYORIGIN* pOrigin) type_GetThemePropertyOrigin;

//---------------------------------------------------------------------------
//  SetWindowTheme()
//                      - redirects an existing Window to use a different
//                        section of the current theme information than its
//                        class normally asks for.
//
//  hwnd                - the handle of the window (cannot be NULL)
//
//  pszSubAppName       - app (group) name to use in place of the calling
//                        app's name.  If NULL, the actual calling app
//                        name will be used.
//
//  pszSubIdList        - semicolon separated list of class Id names to
//                        use in place of actual list passed by the
//                        window's class.  if NULL, the id list from the
//                        calling class is used.
//---------------------------------------------------------------------------
// The Theme Manager will remember the "pszSubAppName" and the
// "pszSubIdList" associations thru the lifetime of the window (even
// if themes are subsequently changed).  The window is sent a
// "WM_THEMECHANGED" msg at the end of this call, so that the new
// theme can be found and applied.
//---------------------------------------------------------------------------
// When "pszSubAppName" or "pszSubIdList" are NULL, the Theme Manager
// removes the previously remember association.  To turn off theme-ing for
// the specified window, you can pass an empty string (L"") so it
// won't match any section entries.
//---------------------------------------------------------------------------
HRESULT SetWindowTheme(HWND hwnd, LPCWSTR pszSubAppName, LPCWSTR pszSubIdList);

alias HRESULT function(HWND hwnd, LPCWSTR pszSubAppName, LPCWSTR pszSubIdList) type_SetWindowTheme;

//---------------------------------------------------------------------------
//  GetThemeFilename()  - Get the value for the specified FILENAME property.
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to search for
//  pszThemeFileName    - output buffer to receive the filename
//  cchMaxBuffChars     - the size of the return buffer, in chars
//---------------------------------------------------------------------------
HRESULT GetThemeFilename(HTHEME hTheme, int iPartId, int iStateId, int iPropId
                         , /*out*/ LPWSTR pszThemeFileName, int cchMaxBuffChars);

alias HRESULT function(HTHEME hTheme, int iPartId, int iStateId, int iPropId
                       , /*out*/ LPWSTR pszThemeFileName, int cchMaxBuffChars) type_GetThemeFilename;

//---------------------------------------------------------------------------
//  GetThemeSysColor()  - Get the value of the specified System color.
//
//  hTheme              - the theme data handle.  if non-NULL, will return
//                        color from [SysMetrics] section of theme.
//                        if NULL, will return the global system color.
//
//  iColorId            - the system color index defined in winuser.h
//---------------------------------------------------------------------------
COLORREF GetThemeSysColor(HTHEME hTheme, int iColorId);

alias COLORREF function(HTHEME hTheme, int iColorId) type_GetThemeSysColor;

//---------------------------------------------------------------------------
//  GetThemeSysColorBrush()
//                      - Get the brush for the specified System color.
//
//  hTheme              - the theme data handle.  if non-NULL, will return
//                        brush matching color from [SysMetrics] section of
//                        theme.  if NULL, will return the brush matching
//                        global system color.
//
//  iColorId            - the system color index defined in winuser.h
//---------------------------------------------------------------------------
HBRUSH GetThemeSysColorBrush(HTHEME hTheme, int iColorId);

alias HBRUSH function(HTHEME hTheme, int iColorId) type_GetThemeSysColorBrush;

//---------------------------------------------------------------------------
//  GetThemeSysBool()   - Get the boolean value of specified System metric.
//
//  hTheme              - the theme data handle.  if non-NULL, will return
//                        BOOL from [SysMetrics] section of theme.
//                        if NULL, will return the specified system boolean.
//
//  iBoolId             - the TMT_XXX BOOL number (first BOOL
//                        is TMT_FLATMENUS)
//---------------------------------------------------------------------------
BOOL GetThemeSysBool(HTHEME hTheme, int iBoolId);

alias BOOL function(HTHEME hTheme, int iBoolId) type_GetThemeSysBool;

//---------------------------------------------------------------------------
//  GetThemeSysSize()   - Get the value of the specified System size metric.
//                        (scaled for the current logical screen dpi)
//
//  hTheme              - the theme data handle.  if non-NULL, will return
//                        size from [SysMetrics] section of theme.
//                        if NULL, will return the global system metric.
//
//  iSizeId             - the following values are supported when
//                        hTheme is non-NULL:
//
//                          SM_CXBORDER   (border width)
//                          SM_CXVSCROLL  (scrollbar width)
//                          SM_CYHSCROLL  (scrollbar height)
//                          SM_CXSIZE     (caption width)
//                          SM_CYSIZE     (caption height)
//                          SM_CXSMSIZE   (small caption width)
//                          SM_CYSMSIZE   (small caption height)
//                          SM_CXMENUSIZE (menubar width)
//                          SM_CYMENUSIZE (menubar height)
//
//                        when hTheme is NULL, iSizeId is passed directly
//                        to the GetSystemMetrics() function
//---------------------------------------------------------------------------
int GetThemeSysSize(HTHEME hTheme, int iSizeId);

alias int function(HTHEME hTheme, int iSizeId) type_GetThemeSysSize;

//---------------------------------------------------------------------------
//  GetThemeSysFont()   - Get the LOGFONT for the specified System font.
//
//  hTheme              - the theme data handle.  if non-NULL, will return
//                        font from [SysMetrics] section of theme.
//                        if NULL, will return the specified system font.
//
//  iFontId             - the TMT_XXX font number (first font
//                        is TMT_CAPTIONFONT)
//
//  plf                 - ptr to LOGFONT to receive the font value.
//                        (scaled for the current logical screen dpi)
//---------------------------------------------------------------------------
HRESULT GetThemeSysFont(HTHEME hTheme, int iFontId, /*out*/ LOGFONTW* plf);

alias HRESULT function(HTHEME hTheme, int iFontId, /*out*/ LOGFONTW* plf) type_GetThemeSysFont;

//---------------------------------------------------------------------------
//  GetThemeSysString() - Get the value of specified System string metric.
//
//  hTheme              - the theme data handle (required)
//
//  iStringId           - must be one of the following values:
//
//                          TMT_CSSNAME
//                          TMT_XMLNAME
//
//  pszStringBuff       - the buffer to receive the string value
//
//  cchMaxStringChars   - max. number of chars that pszStringBuff can hold
//---------------------------------------------------------------------------
HRESULT GetThemeSysString(HTHEME hTheme, int iStringId
                          , /*out*/ LPWSTR pszStringBuff, int cchMaxStringChars);

alias HRESULT function(HTHEME hTheme, int iStringId
                       , /*out*/ LPWSTR pszStringBuff, int cchMaxStringChars) type_GetThemeSysString;

//---------------------------------------------------------------------------
//  GetThemeSysInt() - Get the value of specified System int.
//
//  hTheme              - the theme data handle (required)
//
//  iIntId              - must be one of the following values:
//
//                          TMT_DPIX
//                          TMT_DPIY
//                          TMT_MINCOLORDEPTH
//
//  piValue             - ptr to int to receive value
//---------------------------------------------------------------------------
HRESULT GetThemeSysInt(HTHEME hTheme, int iIntId, int* piValue);

alias HRESULT function(HTHEME hTheme, int iIntId, int* piValue) type_GetThemeSysInt;

//---------------------------------------------------------------------------
//  IsThemeActive()     - can be used to test if a system theme is active
//                        for the current user session.
//
//                        use the API "IsAppThemed()" to test if a theme is
//                        active for the calling process.
//---------------------------------------------------------------------------
BOOL IsThemeActive();

alias BOOL function() type_IsThemeActive;

//---------------------------------------------------------------------------
//  IsAppThemed()       - returns TRUE if a theme is active and available to
//                        the current process
//---------------------------------------------------------------------------
BOOL IsAppThemed();

alias BOOL function() type_IsAppThemed;

//---------------------------------------------------------------------------
//  GetWindowTheme()    - if window is themed, returns its most recent
//                        HTHEME from OpenThemeData() - otherwise, returns
//                        NULL.
//
//      hwnd            - the window to get the HTHEME of
//---------------------------------------------------------------------------
HTHEME GetWindowTheme(HWND hwnd);

alias HTHEME function(HWND hwnd) type_GetWindowTheme;

//---------------------------------------------------------------------------
//  EnableThemeDialogTexture()
//
//  - Enables/disables dialog background theme.  This method can be used to
//    tailor dialog compatibility with child windows and controls that
//    may or may not coordinate the rendering of their client area backgrounds
//    with that of their parent dialog in a manner that supports seamless
//    background texturing.
//
//      hdlg         - the window handle of the target dialog
//      dwFlags      - ETDT_ENABLE to enable the theme-defined dialog background texturing,
//                     ETDT_DISABLE to disable background texturing,
//                     ETDT_ENABLETAB to enable the theme-defined background
//                          texturing using the Tab texture
//---------------------------------------------------------------------------

const uint ETDT_DISABLE       = 0x00000001;
const uint ETDT_ENABLE        = 0x00000002;
const uint ETDT_USETABTEXTURE = 0x00000004;
const uint ETDT_ENABLETAB     = (ETDT_ENABLE | ETDT_USETABTEXTURE);

HRESULT EnableThemeDialogTexture(HWND hwnd, DWORD dwFlags);

alias HRESULT function(HWND hwnd, DWORD dwFlags) type_EnableThemeDialogTexture;

//---------------------------------------------------------------------------
//  IsThemeDialogTextureEnabled()
//
//  - Reports whether the dialog supports background texturing.
//
//      hdlg         - the window handle of the target dialog
//---------------------------------------------------------------------------
BOOL IsThemeDialogTextureEnabled(HWND hwnd);

alias BOOL function(HWND hwnd) type_IsThemeDialogTextureEnabled;

//---------------------------------------------------------------------------
//---- flags to control theming within an app ----

const uint STAP_ALLOW_NONCLIENT  = (1 << 0);
const uint STAP_ALLOW_CONTROLS   = (1 << 1);
const uint STAP_ALLOW_WEBCONTENT = (1 << 2);

//---------------------------------------------------------------------------
//  GetThemeAppProperties()
//                      - returns the app property flags that control theming
//---------------------------------------------------------------------------
DWORD GetThemeAppProperties();

alias DWORD function() type_GetThemeAppProperties;

//---------------------------------------------------------------------------
//  SetThemeAppProperties()
//                      - sets the flags that control theming within the app
//
//      dwFlags         - the flag values to be set
//---------------------------------------------------------------------------
void SetThemeAppProperties(DWORD dwFlags);

alias void function(DWORD dwFlags) type_SetThemeAppProperties;

//---------------------------------------------------------------------------
//  GetCurrentThemeName()
//                      - Get the name of the current theme in-use.
//                        Optionally, return the ColorScheme name and the
//                        Size name of the theme.
//
//  pszThemeFileName    - receives the theme path & filename
//  cchMaxNameChars     - max chars allowed in pszNameBuff
//
//  pszColorBuff        - (optional) receives the canonical color scheme name
//                        (not the display name)
//  cchMaxColorChars    - max chars allowed in pszColorBuff
//
//  pszSizeBuff         - (optional) receives the canonical size name
//                        (not the display name)
//  cchMaxSizeChars     - max chars allowed in pszSizeBuff
//---------------------------------------------------------------------------
HRESULT GetCurrentThemeName(/*out*/ LPWSTR pszThemeFileName, int cchMaxNameChars
                            , /*out*/ /*OPTIONAL*/ LPWSTR pszColorBuff, int cchMaxColorChars
                            , /*out*/ /*OPTIONAL*/ LPWSTR pszSizeBuff, int cchMaxSizeChars);

alias HRESULT function(/*out*/ LPWSTR pszThemeFileName, int cchMaxNameChars
                       , /*out*/ /*OPTIONAL*/ LPWSTR pszColorBuff, int cchMaxColorChars
                       , /*out*/ /*OPTIONAL*/ LPWSTR pszSizeBuff, int cchMaxSizeChars) type_GetCurrentThemeName;

//---------------------------------------------------------------------------
//  GetThemeDocumentationProperty()
//                      - Get the value for the specified property name from
//                        the [documentation] section of the themes.ini file
//                        for the specified theme.  If the property has been
//                        localized in the theme files string table, the
//                        localized version of the property value is returned.
//
//  pszThemeFileName    - filename of the theme file to query
//  pszPropertyName     - name of the string property to retreive a value for
//  pszValueBuff        - receives the property string value
//  cchMaxValChars      - max chars allowed in pszValueBuff
//---------------------------------------------------------------------------

//#define SZ_THDOCPROP_DISPLAYNAME                L"DisplayName"
//#define SZ_THDOCPROP_CANONICALNAME              L"ThemeName"
//#define SZ_THDOCPROP_TOOLTIP                    L"ToolTip"
//#define SZ_THDOCPROP_AUTHOR                     L"author"

const WCHAR[] SZ_THDOCPROP_DISPLAYNAME   = cast(wchar[])"DisplayName";
const WCHAR[] SZ_THDOCPROP_CANONICALNAME = cast(wchar[])"ThemeName";
const WCHAR[] SZ_THDOCPROP_TOOLTIP       = cast(wchar[])"ToolTip";
const WCHAR[] SZ_THDOCPROP_AUTHOR        = cast(wchar[])"author";

HRESULT GetThemeDocumentationProperty(LPCWSTR pszThemeName
                                      , LPCWSTR pszPropertyName
                                      , /*out*/ LPWSTR pszValueBuff
                                      , int cchMaxValChars);

alias HRESULT function(LPCWSTR pszThemeName
                       , LPCWSTR pszPropertyName
                       , /*out*/ LPWSTR pszValueBuff
                       , int cchMaxValChars) type_GetThemeDocumentationProperty;

//---------------------------------------------------------------------------
//  Theme API Error Handling
//
//      All functions in the Theme API not returning an HRESULT (THEMEAPI_)
//      use the WIN32 function "SetLastError()" to record any call failures.
//
//      To retreive the error code of the last failure on the
//      current thread for these type of API's, use the WIN32 function
//      "GetLastError()".
//
//      All Theme API error codes (HRESULT's and GetLastError() values)
//      should be normal win32 errors which can be formatted into
//      strings using the Win32 API FormatMessage().
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
// DrawThemeParentBackground()
//                      - used by partially-transparent or alpha-blended
//                        child controls to draw the part of their parent
//                        that they appear in front of.
//
//  hwnd                - handle of the child control

//  hdc                 - hdc of the child control

//  prc                 - (optional) rect that defines the area to be
//                        drawn (CHILD coordinates)
//---------------------------------------------------------------------------
HRESULT DrawThemeParentBackground(HWND hwnd, HDC hdc, /*OPTIONAL*/ RECT* prc);

alias HRESULT function(HWND hwnd, HDC hdc, /*OPTIONAL*/ RECT* prc) type_DrawThemeParentBackground;

//---------------------------------------------------------------------------
//  EnableTheming()     - enables or disables themeing for the current user
//                        in the current and future sessions.
//
//  fEnable             - if FALSE, disable theming & turn themes off.
//                      - if TRUE, enable themeing and, if user previously
//                        had a theme active, make it active now.
//---------------------------------------------------------------------------
HRESULT EnableTheming(BOOL fEnable);

alias HRESULT function(BOOL fEnable) type_EnableTheming;

//------------------------------------------------------------------------
//---- bits used in dwFlags of DTBGOPTS ----
const uint DTBG_CLIPRECT    = 0x00000001;          // rcClip has been specified
const uint DTBG_DRAWSOLID   = 0x00000002;          // draw transparent/alpha images as solid
const uint DTBG_OMITBORDER  = 0x00000004;          // don't draw border of part
const uint DTBG_OMITCONTENT = 0x00000008;          // don't draw content area of part

const uint DTBG_COMPUTINGREGION = 0x00000010;      // TRUE if calling to compute region

const uint DTBG_MIRRORDC = 0x00000020;             // assume the hdc is mirrorred and
                                                   // flip images as appropriate (currently
                                                   // only supported for bgtype=imagefile)
//------------------------------------------------------------------------
struct DTBGOPTS
{
    DWORD dwSize;               // size of the struct
    DWORD dwFlags;              // which options have been specified
    RECT rcClip;                // clipping rectangle
};

alias DTBGOPTS* PDTBGOPTS;

//------------------------------------------------------------------------
//  DrawThemeBackgroundEx()
//                      - draws the theme-specified border and fill for
//                        the "iPartId" and "iStateId".  This could be
//                        based on a bitmap file, a border and fill, or
//                        other image description.  NOTE: This will be
//                        merged back into DrawThemeBackground() after
//                        BETA 2.
//
//  hTheme              - theme data handle
//  hdc                 - HDC to draw into
//  iPartId             - part number to draw
//  iStateId            - state number (of the part) to draw
//  pRect               - defines the size/location of the part
//  pOptions            - ptr to optional params
//------------------------------------------------------------------------
HRESULT DrawThemeBackgroundEx(HTHEME hTheme, HDC hdc, int iPartId, int iStateId
                              , in RECT* pRect, /*OPTIONAL*/ in DTBGOPTS* pOptions);

alias HRESULT function(HTHEME hTheme, HDC hdc, int iPartId, int iStateId
                       , in RECT* pRect, /*OPTIONAL*/ in DTBGOPTS* pOptions) type_DrawThemeBackgroundEx;
}
