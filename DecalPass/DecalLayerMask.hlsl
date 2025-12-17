// Function Name (Custom Function node): DecalLayerMaskTest
// Inputs  : float4 RenderingLayerSample, float DecalLayerMask
// Outputs : float Out

void DecalLayerMask_float(float RenderingLayerSample, float DecalLayerMask, out float Out)
{
    // Sur la plupart des versions HDRP récentes, le mask est lisible dans .x.
    // Si votre node renvoie un float au lieu d’un float4, branchez-le sur .x côté graphe.
    uint sampled = (uint) round(RenderingLayerSample);
    uint wanted = (uint) round(DecalLayerMask);

    // 1.0 si au moins un bit correspond, sinon 0.0
    Out = ((sampled & wanted) != 0u) ? 1.0 : 0.0;
}
