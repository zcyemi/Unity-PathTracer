using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(CSGcontainer))]
public class CSGcontainerEditor : Editor {

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        CSGcontainer container = target as CSGcontainer;

        EditorGUILayout.BeginHorizontal();
        if(GUILayout.Button("Add"))
        {
            container.AddPrimitive();
        }
        EditorGUILayout.EndHorizontal();
    }


}

[CustomEditor(typeof(CSGPrimitive))]
public class CSGPrimitiveEditor:Editor
{
    public override void OnInspectorGUI()
    {
        var p = target as CSGPrimitive;

        EditorGUI.BeginChangeCheck();
        base.OnInspectorGUI();
        if(EditorGUI.EndChangeCheck())
        {
            PathTracerCamera.Instance.ResetRender();
        }
    }
}