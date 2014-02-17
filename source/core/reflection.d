module core.reflection;

/**
 * Meant to be added to members for making them YAML accessible.
 * Example:
 * ---
 * class Test : GameObject
 * {
 *     @Tweakable
 *     int x;
 * }
 * ---
 */
struct Tweakable
{

}
