using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class MyFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class mysetting
    {
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material mymat;
        public int matpassindex = -1;
    }

    public mysetting setting = new mysetting();

    public override void Create()
    {
        //计算材质球里总的pass数，如果没有则为1
        int passint = setting.mymat == null ? 1 : setting.mymat.passCount - 1;
        //把设置里的pass的id限制在-1到材质的最大pass
        setting.matpassindex = Mathf.Clamp(setting.matpassindex, -1, passint);
        //实例化一下并传参
        
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        throw new System.NotImplementedException();
    }
}
