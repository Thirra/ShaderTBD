using System.Collections;
using System.Collections.Generic;
using audio;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraShaderScript : MonoBehaviour
{
    private Camera cam;
    private Camera maskCam;

    public Material compositeMat;
    public Material stripAlphaMat;

    //I guess this will shange?
    public float speed = 1.0f;
    public float scaleFactor = 1.0f;
    public float magnitude = 0.01f;

    private int scaledWidth;
    private int scaledHeight;

    public MusicTest musicTest;
    float t = 0;

	// Use this for initialization
	void Start ()
    {
        cam = GetComponent<Camera>();
        scaledWidth = (int)(Screen.width * scaleFactor);
        scaledHeight = (int)(Screen.height * scaleFactor);

        cam.cullingMask = ~(1 << LayerMask.NameToLayer("Distortion"));
        cam.depthTextureMode = DepthTextureMode.Depth;

        maskCam = new GameObject("Distort Mask Cam").AddComponent<Camera>();
        maskCam.enabled = false;
        maskCam.clearFlags = CameraClearFlags.Nothing;

        musicTest = GameObject.FindGameObjectWithTag("Audio").GetComponent<MusicTest>();
	}

    private void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        RenderTexture distortingRT = RenderTexture.GetTemporary(scaledWidth, scaledHeight, 24, RenderTextureFormat.ARGBFloat);
        Graphics.Blit(src, distortingRT, stripAlphaMat);

        maskCam.CopyFrom(cam);
        maskCam.gameObject.transform.position = transform.position;
        maskCam.gameObject.transform.rotation = transform.rotation;

        //draw the distorting objects into the buffer
        maskCam.clearFlags = CameraClearFlags.Depth;
        maskCam.cullingMask = 1 << LayerMask.NameToLayer("Distortion");
        maskCam.SetTargetBuffers(distortingRT.colorBuffer, distortingRT.depthBuffer);
        maskCam.Render();

        //Composite pass
        compositeMat.SetTexture("_DistortionRT", distortingRT);
        Graphics.Blit(src, dst, compositeMat);

        RenderTexture.ReleaseTemporary(distortingRT); 
    }

    // Update is called once per frame
    void Update()
    {
        scaleFactor = Mathf.Clamp(scaleFactor, 0.01f, 1.0f);
        scaledWidth = (int)(Screen.width * scaleFactor);
        scaledHeight = (int)(Screen.height * scaleFactor);

        magnitude = Mathf.Max(0.0f, magnitude);
        Shader.SetGlobalFloat("_DistortionOffset", -Time.time * speed);
        Shader.SetGlobalFloat("_DistortionAmount", magnitude / 100.0f);

        if (musicTest.GetComponent<MusicTest>().frequency == 36)
        {
            magnitude = 0.5f;
        }
        else
        {
            magnitude = 0.1f;
        }
    }
}
