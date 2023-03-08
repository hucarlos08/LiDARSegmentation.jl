using LoopVectorization


function linear_min_max_scale(x, min, max)
    return (x-min)/(max-min)
end


function scale_min_max!(lidar_image::Array{T,3}, output::Array{T, 3}) where{T<:AbstractFloat}
   
    # Get dimensions
    channels::Int = size(lidar_image)[3]

    for n=1:channels
        
        # Get parameters
        min::T, max::T = extrema(lidar_image[:,:,n])

        # Normalization function
        f(x) = linear_min_max_scale(x, min, max)

        @turbo for ind ∈ CartesianIndices(lidar_image[:,:,n]) 
            
            output[ind,n] = f(lidar_image[ind,n])
        end
    end

    return output
end



function scale_min_max(lidar_image::Array{T,3}) where{T<:AbstractFloat}

    # Get dimensions
    height::Int, width::Int, channels::Int = size(lidar_image)

    output::Array{T, 3} = zeros(T, height, width, channels)

    scale_min_max!(lidar_image, output)

    return output
end