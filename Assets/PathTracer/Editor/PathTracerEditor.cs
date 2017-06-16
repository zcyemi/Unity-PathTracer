using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(PathTracerCamera))]
public class PathTracerEditor : Editor {
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if(GUILayout.Button("Reset"))
        {
            (target as PathTracerCamera).ResetRender();
        }
    }
}
