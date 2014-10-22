/**
* Defines the Keyboard input device.
*/
module dash.utility.input.keyboard;
import dash.utility.input.inputsystem;

import gfm.sdl2;

version( DashUseSDL2 )
    /// Defines the Mouse input device.
    alias Keyboard = InputSystem!( KeyboardButtonsSDL, void );
else
    /// Defines the Mouse input device.
    alias Keyboard = InputSystem!( KeyboardButtonsWin, void );

package:
/**
 * Virtual key codes.
 *
 * From: http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx
 */
enum KeyboardButtonsWin: uint
{
    Cancel      = 0x03, /// Control-break
    //Unused    = 0x07,
    Backspace   = 0x08, /// Backspace key
    Tab         = 0x09, /// Tab key
    //Reserved  = 0x0A-0x0B,
    Clear       = 0x0C, /// Clear key
    Return      = 0x0D, /// Enter key
    //Undefined = 0x0E-0x0F
    Shift       = 0x10, /// Shift key
    Control     = 0x11, /// Control key
    Alt         = 0x12, /// Menu/alt key
    Pause       = 0x13, /// Pause key
    CapsLock    = 0x14, /// Capital/Caps Lock key
    //Who Cares = 0x15-0x1A,
    Escape      = 0x1B, /// Escape key
    //Who Cares = 0x1C-0x1F
    Space       = 0x20, /// Space bar
    PageUp      = 0x21, /// Page Up/Prior key
    PageDown    = 0x22, /// Page Down/Next key
    End         = 0x23, /// End key
    Home        = 0x24, /// Home key
    Left        = 0x25, /// Left arrow key
    Up          = 0x26, /// Up arrow key
    Right       = 0x27, /// Right arrow key
    Down        = 0x28, /// Down arrow key
    Select      = 0x29, /// Select key
    Print       = 0x2A, /// Print key
    Execute     = 0x2B, /// Execute key
    PrintScreen = 0x2C, /// Print Screen/Snapshot key
    Insert      = 0x2D, /// Insert key
    Delete      = 0x2E, /// Delete key
    Help        = 0x2F, /// Help key
    Keyboard0   = 0x30, /// 0 key
    Keyboard1   = 0x31, /// 1 key
    Keyboard2   = 0x32, /// 2 key
    Keyboard3   = 0x33, /// 3 key
    Keyboard4   = 0x34, /// 4 key
    Keyboard5   = 0x35, /// 5 key
    Keyboard6   = 0x36, /// 6 key
    Keyboard7   = 0x37, /// 7 key
    Keyboard8   = 0x38, /// 8 key
    Keyboard9   = 0x39, /// 9 key
    //Unused    = 0x3A-0x40
    A           = 0x41, /// A key
    B           = 0x42, /// B key
    C           = 0x43, /// C key
    D           = 0x44, /// D key
    E           = 0x45, /// E key
    F           = 0x46, /// F key
    G           = 0x47, /// G key
    H           = 0x48, /// H key
    I           = 0x49, /// I key
    J           = 0x4A, /// J key
    K           = 0x4B, /// K key
    L           = 0x4C, /// L key
    M           = 0x4D, /// M key
    N           = 0x4E, /// N key
    O           = 0x4F, /// O key
    P           = 0x50, /// P key
    Q           = 0x51, /// Q key
    R           = 0x52, /// R key
    S           = 0x53, /// S key
    T           = 0x54, /// T key
    U           = 0x55, /// U key
    V           = 0x56, /// V key
    W           = 0x57, /// W key
    X           = 0x58, /// X key
    Y           = 0x59, /// Y key
    Z           = 0x5A, /// Z key
    WindowsLeft = 0x5B, /// Left windows key
    WindowsRight= 0x5C, /// Right windows key
    Apps        = 0x5D, /// Applications key
    //Reserved  = 0x5E
    Sleep       = 0x5F, /// Sleep key
    Numpad0     = 0x60, /// 0 key
    Numpad1     = 0x61, /// 1 key
    Numpad2     = 0x62, /// 2 key
    Numpad3     = 0x63, /// 3 key
    Numpad4     = 0x64, /// 4 key
    Numpad5     = 0x65, /// 5 key
    Numpad6     = 0x66, /// 6 key
    Numpad7     = 0x67, /// 7 key
    Numpad8     = 0x68, /// 8 key
    Numpad9     = 0x69, /// 9 key
    Multiply    = 0x6A, /// Multiply key
    Add         = 0x6B, /// Addition key
    Separator   = 0x6C, /// Seperator key
    Subtract    = 0x6D, /// Subtraction key
    Decimal     = 0x6E, /// Decimal key
    Divide      = 0x6F, /// Division key
    F1          = 0x70, /// Function 1 key
    F2          = 0x71, /// Function 2 key
    F3          = 0x72, /// Function 3 key
    F4          = 0x73, /// Function 4 key
    F5          = 0x74, /// Function 5 key
    F6          = 0x75, /// Function 6 key
    F7          = 0x76, /// Function 7 key
    F8          = 0x77, /// Function 8 key
    F9          = 0x78, /// Function 9 key
    F10         = 0x79, /// Function 10 key
    F11         = 0x7A, /// Function 11 key
    F12         = 0x7B, /// Function 12 key
    F13         = 0x7C, /// Function 13 key
    F14         = 0x7D, /// Function 14 key
    F15         = 0x7E, /// Function 15 key
    F16         = 0x7F, /// Function 16 key
    F17         = 0x80, /// Function 17 key
    F18         = 0x81, /// Function 18 key
    F19         = 0x82, /// Function 19 key
    F20         = 0x83, /// Function 20 key
    F21         = 0x84, /// Function 21 key
    F22         = 0x85, /// Function 22 key
    F23         = 0x86, /// Function 23 key
    F24         = 0x87, /// Function 24 key
    //Unused    = 0x88-0x8F,
    NumLock     = 0x90, /// Num Lock key
    ScrollLock  = 0x91, /// Scroll Lock key
    //OEM       = 0x92-0x96,
    //Unused    = 0x97-0x9F,
    ShiftLeft   = 0xA0, /// Left shift key
    ShiftRight  = 0xA1, /// Right shift key
    ControlLeft = 0xA2, /// Left control key
    ControlRight= 0xA3, /// Right control key
    AltLeft     = 0xA4, /// Left Alt key
    AltRight    = 0xA5, /// Right Alt key
    END,
}

enum KeyboardButtonsSDL: uint
{
    Cancel      = SDLK_CANCEL, /// Control-break
    //Unused    = 0x07,
    Backspace   = SDLK_BACKSPACE, /// Backspace key
    Tab         = SDLK_TAB, /// Tab key
    //Reserved  = 0x0A-0x0B,
    Clear       = SDLK_CLEAR, /// Clear key
    Return      = SDLK_RETURN, /// Enter key
    //Undefined = 0x0E-0x0F
    // * See Left/Right Shift, Ctrl, Alt below *
    //Shift       = SDLK_LSHIFT, /// Shift key
    //Control     = SDLK_LCTRL, /// Control key
    //Alt         = SDLK_LALT, /// Menu/alt key
    //
    Pause       = SDLK_PAUSE, /// Pause key
    CapsLock    = SDLK_CAPSLOCK,
    //Who Cares = 0x15-0x1A,
    Escape      = SDLK_ESCAPE,
    //Who Cares = 0x1C-0x1F
    Space       = SDLK_SPACE, /// Space bar
    PageUp      = SDLK_PAGEUP, /// Page Up/Prior key
    PageDown    = SDLK_PAGEDOWN, /// Page Down/Next key
    End         = SDLK_END, /// End key
    Home        = SDLK_HOME, /// Home key
    Left        = SDLK_LEFT, /// Left arrow key
    Up          = SDLK_UP, /// Up arrow key
    Right       = SDLK_RIGHT, /// Right arrow key
    Down        = SDLK_DOWN, /// Down arrow key
    Select      = SDLK_SELECT, /// Select key
    Print       = SDLK_PRINTSCREEN, /// Print key
    PrintScreen = SDLK_PRINTSCREEN, /// Print Screen/Snapshot key
    Execute     = SDLK_EXECUTE, /// Execute key
    Insert      = SDLK_INSERT, /// Insert key
    Delete      = SDLK_DELETE, /// Delete key
    Help        = SDLK_HELP, /// Help key
    Keyboard0   = SDLK_0, /// 0 key
    Keyboard1   = SDLK_1, /// 1 key
    Keyboard2   = SDLK_2, /// 2 key
    Keyboard3   = SDLK_3, /// 3 key
    Keyboard4   = SDLK_4, /// 4 key
    Keyboard5   = SDLK_5, /// 5 key
    Keyboard6   = SDLK_6, /// 6 key
    Keyboard7   = SDLK_7, /// 7 key
    Keyboard8   = SDLK_8, /// 8 key
    Keyboard9   = SDLK_9, /// 9 key
    //Unused    = 0x3A-0x40
    A           = SDLK_a, /// A key
    B           = SDLK_b, /// B key
    C           = SDLK_c, /// C key
    D           = SDLK_d, /// D key
    E           = SDLK_e, /// E key
    F           = SDLK_f, /// F key
    G           = SDLK_g, /// G key
    H           = SDLK_h, /// H key
    I           = SDLK_i, /// I key
    J           = SDLK_j, /// J key
    K           = SDLK_k, /// K key
    L           = SDLK_l, /// L key
    M           = SDLK_m, /// M key
    N           = SDLK_n, /// N key
    O           = SDLK_o, /// O key
    P           = SDLK_p, /// P key
    Q           = SDLK_q, /// Q key
    R           = SDLK_r, /// R key
    S           = SDLK_s, /// S key
    T           = SDLK_t, /// T key
    U           = SDLK_u, /// U key
    V           = SDLK_v, /// V key
    W           = SDLK_w, /// W key
    X           = SDLK_x, /// X key
    Y           = SDLK_y, /// Y key
    Z           = SDLK_z, /// Z key
    GuiLeft     = SDLK_LGUI, /// Left GUI key
    GuiRight    = SDLK_RGUI, /// Right GUI key
    Apps        = SDLK_APPLICATION, /// Applications key
    //Reserved  = 0x5E
    Sleep       = SDLK_SLEEP, /// Sleep key
    Numpad0     = SDLK_KP_0, /// 0 key
    Numpad1     = SDLK_KP_1, /// 1 key
    Numpad2     = SDLK_KP_2, /// 2 key
    Numpad3     = SDLK_KP_3, /// 3 key
    Numpad4     = SDLK_KP_4, /// 4 key
    Numpad5     = SDLK_KP_5, /// 5 key
    Numpad6     = SDLK_KP_6, /// 6 key
    Numpad7     = SDLK_KP_7, /// 7 key
    Numpad8     = SDLK_KP_8, /// 8 key
    Numpad9     = SDLK_KP_9, /// 9 key
    // * Unused *
    //Multiply    = 0x6A, /// Multiply key
    //Add         = 0x6B, /// Addition key
    //Separator   = 0x6C, /// Seperator key
    //Subtract    = 0x6D, /// Subtraction key
    //Decimal     = 0x6E, /// Decimal key
    //Divide      = 0x6F, /// Division key
    F1          = SDLK_F1, /// Function 1 key
    F2          = SDLK_F2, /// Function 2 key
    F3          = SDLK_F3, /// Function 3 key
    F4          = SDLK_F4, /// Function 4 key
    F5          = SDLK_F5, /// Function 5 key
    F6          = SDLK_F6, /// Function 6 key
    F7          = SDLK_F7, /// Function 7 key
    F8          = SDLK_F8, /// Function 8 key
    F9          = SDLK_F9, /// Function 9 key
    F10         = SDLK_F10, /// Function 10 key
    F11         = SDLK_F11, /// Function 11 key
    F12         = SDLK_F12, /// Function 12 key
    F13         = SDLK_F13, /// Function 13 key
    F14         = SDLK_F14, /// Function 14 key
    F15         = SDLK_F15, /// Function 15 key
    F16         = SDLK_F16, /// Function 16 key
    F17         = SDLK_F17, /// Function 17 key
    F18         = SDLK_F18, /// Function 18 key
    F19         = SDLK_F19, /// Function 19 key
    F20         = SDLK_F20, /// Function 20 key
    F21         = SDLK_F21, /// Function 21 key
    F22         = SDLK_F22, /// Function 22 key
    F23         = SDLK_F23, /// Function 23 key
    F24         = SDLK_F24, /// Function 24 key
    //Unused    = 0x88-0x8F,
    NumLock     = SDLK_NUMLOCKCLEAR, /// Num Lock key
    ScrollLock  = SDLK_SCROLLLOCK, /// Scroll Lock key
    //OEM       = 0x92-0x96,
    //Unused    = 0x97-0x9F,
    ShiftLeft   = SDLK_LSHIFT, /// Left shift key
    ShiftRight  = SDLK_LSHIFT, /// Right shift key
    ControlLeft = SDLK_LCTRL, /// Left control key
    ControlRight= SDLK_RCTRL, /// Right control key
    AltLeft     = SDLK_LALT, /// Left Alt key
    AltRight    = SDLK_RALT, /// Right Alt key
    END,
}