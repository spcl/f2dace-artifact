
In the generated code, comment out the following line.

```cpp
perm_PEXTRA_sdfg_0_0_508(__state, &PEXTRA[0], &PEXTRA_in_view[0], NBLOCKS);       ////__DACE:0:0:508    ////__DACE:0
cudaMemcpyAsync(__state->__0_PEXTRA_perm_gpu, __state->__0_PEXTRA_perm, (137 * NBLOCKS) * sizeof(double), cudaMemcpyHostToDevice, __state->gpu_context->streams[62]);    ////__DACE:0:0:187,421    ////__DACE:0
```

Then add measurement code around the main map:

```cpp
    cudaDeviceSynchronize();
    auto start = std::chrono::high_resolution_clock::now();                                                                                                                                                                                           
        __dace_runkernel_stateCLOUDSC_map_0_0_316(__state, __state->__0_KTYPE_gpu, __state->__0_LDCUM_gpu, __state->__0_PAPH_perm_gpu, __state->__0_PAP_perm_gpu, __state->__0_PA_perm_gpu, __state->__0_PCCN_perm_gpu, __state->__0_PCLV_perm_gpu, __state->__0_PCOVPTOT_perm_gpu, __state->__0_PDYNA_perm_gpu, __state->__0_PDYNI_perm_gpu, __state->__0_PDYNL_perm_gpu, __state->__0_PEXTRA_perm_gpu, __state->__0_PFCQLNG_perm_gpu, __state->__0_PFCQNNG_perm_gpu, __state->__0_PFCQRNG_perm_gpu, __state->__0_PFCQSNG_perm_gpu, __state->__0_PFHPSL_perm_gpu, __state->__0_PFHPSN_perm_gpu, __state->__0_PFPLSL_perm_gpu, __state->__0_PFPLSN_perm_gpu, __state->__0_PFSQIF_perm_gpu, __state->__0_PFSQITUR_perm_gpu, __state->__0_PFSQLF_perm_gpu, __state->__0_PFSQLTUR_perm_gpu, __state->__0_PFSQRF_perm_gpu, __state->__0_PFSQSF_perm_gpu, __state->__0_PHRLW_perm_gpu, __state->__0_PHRSW_perm_gpu, __state->__0_PICRIT_AER_perm_gpu, __state->__0_PLCRIT_AER_perm_gpu, __state->__0_PLSM_gpu, __state->__0_PLUDE_perm_gpu, __state->__0_PLU_perm_gpu, __state->__0_PMFD_perm_gpu, __state->__0_PMFU_perm_gpu, __state->__0_PNICE_perm_gpu, __state->__0_PQ_perm_gpu, __state->__0_PRAINFRAC_TOPRFZ_gpu, __state->__0_PRE_ICE_perm_gpu, __state->__0_PSNDE_perm_gpu, __state->__0_PSUPSAT_perm_gpu, __state->__0_PT_perm_gpu, __state->__0_PVERVEL_perm_gpu, __state->__0_PVFA_perm_gpu, __state->__0_PVFI_perm_gpu, __state->__0_PVFL_perm_gpu, __state->__0_tendency_cml_T_perm_gpu, __state->__0_tendency_cml_a_perm_gpu, __state->__0_tendency_cml_cld_perm_gpu, __state->__0_tendency_cml_o3_perm_gpu, __state->__0_tendency_cml_q_perm_gpu, __state->__0_tendency_cml_u_perm_gpu, __state->__0_tendency_cml_v_perm_gpu, __state->__0_tendency_loc_T_perm_gpu, __state->__0_tendency_loc_a_perm_gpu, __state->__0_tendency_loc_cld_perm_gpu, __state->__0_tendency_loc_o3_perm_gpu, __state->__0_tendency_loc_q_perm_gpu, __state->__0_tendency_loc_u_perm_gpu, __state->__0_tendency_loc_v_perm_gpu, __state->__0_tendency_tmp_T_perm_gpu, __state->__0_tendency_tmp_a_perm_gpu, __state->__0_tendency_tmp_cld_perm_gpu, __state->__0_tendency_tmp_o3_perm_gpu, __state->__0_tendency_tmp_q_perm_gpu, __state->__0_tendency_tmp_u_perm_gpu, __state->__0_tendency_tmp_v_perm_gpu, LAERICEAUTO, LAERICESED, LAERLIQAUTOLSP, LAERLIQCOLL, LDMAINCALL, LDSLPHY, NBLOCKS, PTSPHY, R2ES, R3IES, R3LES, R4IES, R4LES, R5ALSCP, R5ALVCP, R5IES, R5LES, RALFDCP, RALSDCP, RALVDCP, RAMID, RAMIN, RCCN, RCLCRIT_LAND, RCLCRIT_SEA, RCLDIFF, RCLDIFF_CONVI, RCLDTOPCF, RCL_APB1, RCL_APB2, RCL_APB3, RCL_CDENOM1, RCL_CDENOM2, RCL_CDENOM3, RCL_CONST1I, RCL_CONST1R, RCL_CONST1S, RCL_CONST2I, RCL_CONST2R, RCL_CONST2S, RCL_CONST3I, RCL_CONST3R, RCL_CONST3S, RCL_CONST4I, RCL_CONST4R, RCL_CONST4S, RCL_CONST5I, RCL_CONST5R, RCL_CONST5S, RCL_CONST6I, RCL_CONST6R, RCL_CONST6S, RCL_CONST7S, RCL_CONST8S, RCL_FAC1, RCL_FAC2, RCL_FZRAB, RCL_KA273, RCL_KKAac, RCL_KKAau, RCL_KKBac, RCL_KKBaun, RCL_KKBauq, RCL_KK_CLOUD_NUM_LAND, RCL_KK_CLOUD_NUM_SEA, RCOVPMIN, RCPD, RD, RDENSREF, RDEPLIQREFDEPTH, RDEPLIQREFRATE, RETV, RG, RICEINIT, RKCONV, RKOOP1, RKOOP2, RKOOPTAU, RLCRITSNOW, RLMIN, RLMLT, RLSTT, RLVTT, RNICE, RPECONS, RPRC1, RPRECRHMAX, RSNOWLIN1, RSNOWLIN2, RTAUMEL, RTHOMO, RTICE, RTICECU, RTT, RTWAT, RTWAT_RTICECU_R, RTWAT_RTICE_R, RV, RVICE, RVRAIN, RVRFACTOR, RVSNOW);    ////__DACE:0:0:316    ////__DACE:0
cudaDeviceSynchronize();
auto end = std::chrono::high_resolution_clock::now();
printf("Time %d [ms]\n", std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count());

```