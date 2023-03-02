module LiDARProjections

using LasIO


export Spherical
export project_point
export make_projection_images

struct Spherical{T<:AbstractFloat}
    # Image propoerties
    img_length::Int
    num_lasers::Int

    # Flied of views properties (radians)
    fov_up::T
    fov_down::T
    fov::T

    # Coordinates origin
    origin::Vector{T}


    function Spherical{T}(config::Dict{String, Any}) where{T<:AbstractFloat}

        # Load the parameters
        img_length   = config["img_length"]
        num_lasers   = config["num_lasers"]

        fov_up      = config["fov_up"]
        fov_down    = config["fov_down"]
        fov         = abs(fov_up) + abs(fov_down)

        origin      = config["origin"]

        new{T}(img_length, num_lasers, fov_up, fov_down, fov, origin)
        
    end
end

function project_point(header::LasHeader, point::LasPoint0, sp::Spherical{T}) where{T<:AbstractFloat}
    
    x::T = (point.x * header.x_scale) - sp.origin[1]
    y::T = (point.y * header.y_scale) - sp.origin[2]
    z::T = (point.z * header.z_scale) - sp.origin[3]

    range::T = sqrt(x^2 + y^2 + z^2)

    # Something goes wrong
    if(iszero(range))
        return 0.0, 0.0, 0.0, false
    end

    yaw::T      = atan(y, x)
    pitch::T    = asin(z / range)

    # Estimate pixel coordinates
    v::T = 0.5 * (yaw / pi + 1.0)
    u::T = 1.0 - (pitch + abs(sp.fov_down)) / sp.fov

    v *= sp.img_length
    u *= sp.num_lasers
    

    # Adjust to image size
    pixel_v::Int = clamp(trunc(Int, v), 0, sp.img_length - 1)
    pixel_u::Int = clamp(trunc(Int, u), 0, sp.num_lasers - 1)
    
    return pixel_v, pixel_u, range, true
end


function make_projection_images(header::LasHeader, cloud_::PointVector{LasPoint0}, sp::Spherical{T}) where{T<:AbstractFloat}
    
    # Set the number of num
    num_channels::Int = length(fieldnames(typeof(LasPoint0)))


    # Create memory for Spherical projection
    spherical_img::Array{T,3}  =  zeros(T, sp.num_lasers, sp.img_length, num_channels + 1)
    
    for point in cloud_
        
        pixel_v::Int, pixel_u::Int, range::T, ok::Bool = project_point(header, point, sp)

        if(ok==false)
            continue
        end

        pixel_v +=1
        pixel_u +=1
        
        # Add point propoerties
        for i in 1:num_channels
            spherical_img[pixel_u, pixel_v, i] = T(getfield(point, i))
        end

        # Add range
        spherical_img[pixel_u, pixel_v, end] = T(range)
        
    end

    return spherical_img
    
end



end # end module 