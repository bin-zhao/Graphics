using UnityEngine;
using UnityEditor;

namespace UnityEditor.Experimental.Rendering.LWRP.Path2D
{
    internal class ShapeEditorUtility
    {
        public static int Mod(int x, int m)
        {
            int r = x % m;
            return r < 0 ? r + m : r;
        }
    }
}
