import SimpleITK as sitk
    
def apply_registration(im_target, im_source, reg, interp_method):
    rs = sitk.ResampleImageFilter()
    if interp_method == 'nn':
        rs.SetInterpolator(sitk.sitkNearestNeighbor)
    elif interp_method == 'linear':
        rs.SetInterpolator(sitk.sitkLinear)
    
    rs.SetReferenceImage(im_target)
    rs.SetTransform(reg)

    im_registered = rs.Execute(im_source)
    
    return im_registered

def im_register(im_target, im_source, im_mask_roi, n_iters, i_radius, g_factor, s_factor, initial_transform = None):
    reg_method = sitk.ImageRegistrationMethod()
    
    if initial_transform == None:
        initial_transform = sitk.CenteredTransformInitializer(im_target, im_source, sitk.AffineTransform(im_target.GetDimension()), sitk.CenteredTransformInitializerFilter.GEOMETRY)
    
    reg_method.SetInitialTransform(initial_transform, inPlace = False)

    reg_method.SetMetricFixedMask(im_mask_roi)

    reg_method.SetMetricAsMattesMutualInformation(numberOfHistogramBins = 64)
    reg_method.SetMetricSamplingStrategy(reg_method.RANDOM)
    reg_method.SetMetricSamplingPercentage(1.00)

    reg_method.SetInterpolator(sitk.sitkLinear)

    reg_method.SetOptimizerAsOnePlusOneEvolutionary(numberOfIterations = n_iters, initialRadius = i_radius, growthFactor = g_factor, shrinkFactor = s_factor)
    reg_method.SetOptimizerScalesFromPhysicalShift() 

    reg_method.SetShrinkFactorsPerLevel(shrinkFactors = [4, 2, 1])
    reg_method.SetSmoothingSigmasPerLevel(smoothingSigmas=[2, 1, 0])
    reg_method.SmoothingSigmasAreSpecifiedInPhysicalUnitsOn()

    reg = reg_method.Execute(sitk.Cast(im_target, sitk.sitkFloat32), sitk.Cast(im_source, sitk.sitkFloat32))
    
    im_registered = apply_registration(im_target, im_source, reg, 'linear')
    
    return im_registered, reg