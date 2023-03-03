using LasIO
using StaticArrays
using LinearAlgebra


struct SphericalProjection{T<:AbstractFloat}
    
    # Laser bean number
    num_lasers::Int

    # Image properties
    height::Int   
    width::Int

    # Flied of views properties (radians)
    fov_up::T
    fov_down::T
    fov_horizontal::T
    fov::T

    function SphericalProjection{T}(config::Dict{String, Real}) where {T<:AbstractFloat}

        # Load the parameters

        num_lasers = config["num_lasers"]

        height = num_lasers # Image height

        fov_horizontal = config["horizontal_fov"]

        # Estimate image width using highest power of 2 less than or equal to given number
        w::T    = trunc(Int, (2*pi)/fov_horizontal)
        p::T    = trunc(Int, log2(w))
        width   = trunc(Int, 2^p) # Image width

        fov_up = config["fov_up"]
        fov_down = config["fov_down"]

        # Complete field of view
        fov = abs(fov_up) + abs(fov_down)

        new{T}(num_lasers, height, width, fov_up, fov_down, fov_horizontal, fov)

    end
end

function get_point_coordinates(point::SVector{3,T}, origin::SVector{3,T}, scale::SVector{3,T}, offset::SVector{3,T}) where {T<:AbstractFloat}
    return ((point .* scale) + offset) - origin
end


function get_spherical_coordinates(
    point::SVector{3,T}, 
    origin::SVector{3,T}, 
    scale::SVector{3,T}, 
    offset::SVector{3,T}, 
    sp::SphericalProjection{T}) where {T<:AbstractFloat}

    p3D::SVector{3,T} = get_point_coordinates(point, origin, scale, offset)

    range::T = norm(p3D)

    # Something goes wrong
    if (iszero(range))
        return -1, -1, range
    end

    yaw::T      = atan(p3D.y, p3D.x)
    pitch::T    = asin(p3D.z / range)

    # Estimate pixel coordinates (u,v)
    u::T = sp.height * (1.0 - (pitch + abs(sp.fov_down)) / sp.fov)
    v::T = sp.width  * (0.5 * ((yaw / pi) + 1.0))

    # Adjust to image size
    pixel_u::Int = clamp(trunc(Int, u), 1, sp.height)
    pixel_v::Int = clamp(trunc(Int, v), 1, sp.width)

    return pixel_u, pixel_v, range

end


function create_spherical_image(header::LasHeader, cloud::PointVector{LP}, sp::SphericalProjection{T}, origin::SVector{3,T}) where {LP<:LasPoint, T<:AbstractFloat}

    # Set the number of image channels
    num_channels::Int = length(fieldnames(LP))

    # Create memory for Spherical projection
    spherical_img::Array{T,3} = zeros(T, sp.height, sp.width, num_channels + 1)

    scale::SVector{3,T}     =  SVector{3,T}(header.x_scale, header.y_scale,   header.z_scale)
    offset::SVector{3,T}    =  SVector{3,T}(header.x_offset, header.y_offset, header.z_offset)

    for point in cloud

        point_sa::SVector{3,T} = SVector{3,T}(point.x, point.y, point.z) 

        u::Int, v::Int, range::T  = get_spherical_coordinates(point_sa, origin, scale, offset, sp)

        if( u==-1 || v==-1)
            continue
        end

        # Add point propoerties
        for i in 1:num_channels
            spherical_img[u, v, i] = T(getfield(point, i))
        end

        # Add range
        spherical_img[u, v, end] = T(range)

    end

    return spherical_img

end