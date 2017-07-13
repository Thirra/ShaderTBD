using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace audio
{
    [RequireComponent(typeof(AudioSource))]
    public class MusicTest : MonoBehaviour
    {
        public AudioSource audioSource;

        public float frequency = 0.0f;
        public int samplerate = 11024;
        public int index = 0;
        public float amp = 0;
        // Use this for initialization
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {
            frequency = GetFundamentalFrequency();
        }

        float GetFundamentalFrequency()
        {
            Debug.DrawLine(new Vector2(index * 0.01f, 0.0f), new Vector2(index * 0.01f, 10.0f), Color.green);
            Debug.DrawLine(new Vector2(0, amp), new Vector2(100.0f,amp), Color.red);
            float fundamentalFrequency = 0.0f;
            float[] data = new float[1024];
            audioSource.GetSpectrumData(data, 0, FFTWindow.BlackmanHarris);
            float s = 0.0f;
            int i = 0;
            Vector2 lastpos = new Vector2(0, data[0] * 100.0f);
            for (int j = 1; j < 1024; j++)
            {
                Vector2 pos = new Vector2(j*0.01f, data[j] * 100.0f);
                Debug.DrawLine(pos, lastpos);
                lastpos = pos;
                if (s < data[j])
                {
                    s = data[j];
                    i = j;
                }
            }
            fundamentalFrequency = i * samplerate / 1024;
            fundamentalFrequency = 0;
            for (int k = 240; k < 260; ++k)
                if (data[k] > 0.007f)
                    fundamentalFrequency = 36;

            //            fundamentalFrequency = data[255] > 0.005f ? 36 : 0;
           // fundamentalFrequency = 36;
            return fundamentalFrequency;
        }
    }
}
