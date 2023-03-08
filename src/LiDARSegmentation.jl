module LiDARSegmentation

export SphericalProjection
export get_point_coordinates
export get_spherical_coordinates
export create_spherical_image

include("LiDARProjections.jl")


export scale_min_max
export scale_min_max!

include("aux.jl")


end # module LiDARSegmentation
