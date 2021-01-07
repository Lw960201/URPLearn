using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class NewBehaviourScript : MonoBehaviour
{
    public Texture2D inputTexture;
    public RawImage outputImage;
    public ComputeShader shader;

    void Start()
    {
        RenderTexture t =new RenderTexture(inputTexture.width,inputTexture.height,24);
        t.enableRandomWrite = true;
        t.Create();
        outputImage.texture = t;

        int k = shader.FindKernel("CSMain");
        shader.SetTexture(k,"inputTexture",inputTexture);
        shader.SetTexture(k,"outputTexture",t);
        shader.Dispatch(k,inputTexture.width,inputTexture.height,1);
    }

}
