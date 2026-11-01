#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using Blockverse;

public static class BlockverseProjectSetup
{
    [MenuItem("BLOCKVERSE/Setup Starter Scene")]
    public static void CreateStarterScene()
    {
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        var root = new GameObject("BLOCKVERSE");
        var eventSystem = new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
        eventSystem.transform.SetParent(root.transform, false);
        var canvasObject = new GameObject("Canvas", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
        canvasObject.transform.SetParent(root.transform, false);
        var canvas = canvasObject.GetComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        var scaler = canvasObject.GetComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1080, 1920);

        var title = CreateText(canvasObject.transform, "BLOCKVERSE", 64, new Vector2(0, 820), new Vector2(900, 120));
        title.alignment = TextAnchor.MiddleCenter;
        var score = CreateText(canvasObject.transform, "SCORE  0", 42, new Vector2(0, 690), new Vector2(900, 80));
        var goal = CreateText(canvasObject.transform, "LEVEL 1", 30, new Vector2(0, 610), new Vector2(900, 70));

        var board = new GameObject("Board", typeof(RectTransform), typeof(GridLayoutGroup));
        board.transform.SetParent(canvasObject.transform, false);
        var rect = board.GetComponent<RectTransform>();
        rect.sizeDelta = new Vector2(620, 620);
        rect.anchoredPosition = new Vector2(0, 100);

        var controller = root.AddComponent<GameController>();
        var so = new SerializedObject(controller);
        so.FindProperty("boardRoot").objectReferenceValue = rect;
        so.FindProperty("scoreLabel").objectReferenceValue = score;
        so.FindProperty("goalLabel").objectReferenceValue = goal;

        var restart = CreateButton(canvasObject.transform, "RESTART", new Vector2(0, -650));
        so.FindProperty("restartButton").objectReferenceValue = restart;
        so.ApplyModifiedPropertiesWithoutUndo();

        EditorSceneManager.SaveScene(scene, "Assets/Scenes/Game.unity");
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene("Assets/Scenes/Game.unity", true) };
        PlayerSettings.applicationIdentifier = "com.dev.blockverse";
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.Portrait;
        AssetDatabase.SaveAssets();
        Debug.Log("BLOCKVERSE starter scene created at Assets/Scenes/Game.unity.");
    }

    private static Text CreateText(Transform parent, string value, int size, Vector2 position, Vector2 dimensions)
    {
        var go = new GameObject(value, typeof(RectTransform), typeof(Text));
        go.transform.SetParent(parent, false);
        var rect = go.GetComponent<RectTransform>();
        rect.sizeDelta = dimensions;
        rect.anchoredPosition = position;
        var text = go.GetComponent<Text>();
        text.text = value;
        text.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
        text.fontSize = size;
        text.color = Color.white;
        text.alignment = TextAnchor.MiddleCenter;
        return text;
    }

    private static Button CreateButton(Transform parent, string label, Vector2 position)
    {
        var go = new GameObject(label, typeof(RectTransform), typeof(Image), typeof(Button));
        go.transform.SetParent(parent, false);
        var rect = go.GetComponent<RectTransform>();
        rect.sizeDelta = new Vector2(400, 100);
        rect.anchoredPosition = position;
        go.GetComponent<Image>().color = new Color(0.25f, 0.55f, 1f);
        CreateText(go.transform, label, 34, Vector2.zero, new Vector2(380, 90));
        return go.GetComponent<Button>();
    }
}
#endif
