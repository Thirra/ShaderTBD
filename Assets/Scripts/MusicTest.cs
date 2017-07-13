using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class MusicTest : MonoBehaviour
{
    public AudioSource audioSource;

    public float frequency = 0.0f;
    public int samplerate = 11024;

    // Use this for initialization
    void Start ()
    {

	}
	
	// Update is called once per frame
	void Update ()
    {
        frequency = GetFundamentalFrequency();
    }

    float GetFundamentalFrequency()
    {
        float fundamentalFrequency = 0.0f;
        float[] data = new float[8192];
        audioSource.GetSpectrumData(data, 0, FFTWindow.BlackmanHarris);
        float s = 0.0f;
        int i = 0;
        for (int j = 1; j < 8192; j++)
        {
            if (s < data[j])
            {
                s = data[j];
                i = j;
            }
        }
        fundamentalFrequency = i * samplerate / 8192;
        return fundamentalFrequency;
    }
}
