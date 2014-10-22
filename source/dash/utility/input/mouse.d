/**
 * Defines the Mouse input device.
 */
module dash.utility.input.mouse;
import dash.utility.input.inputsystem;

/// Defines the Mouse input device.
alias Mouse = InputSystem!( MouseButtons, MouseAxes );

package:
// Enums of inputs
enum MouseButtons
{
    Left   = 0x01, /// Left mouse button
    Right  = 0x02, /// Right mouse button
    Middle = 0x04, /// Middle mouse button
    X1    = 0x05, /// X1 mouse button
    X2    = 0x06, /// X2 mouse button
    END,
}

/// Axes of input for the mouse.
enum MouseAxes
{
    ScrollWheel,
    XPos,
    YPos,
    END,
}